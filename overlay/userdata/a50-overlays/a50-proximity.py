#!/usr/bin/python3
import fcntl
import os
from pathlib import Path
import socket
import struct
import time

EV_ABS = 3
ABS_DISTANCE = 25
DEVICE_NAME = "A50 Call Proximity"
RUNTIME = Path("/run/a50-proximity")
RAW = Path("/sys/class/sensors/proximity_sensor/raw_data")
EVENT = struct.Struct("@llHHi")


def publish(fd, distance):
    os.write(fd, EVENT.pack(0, 0, EV_ABS, ABS_DISTANCE, distance)
             + EVENT.pack(0, 0, 0, 0, 0))


def create_device(fd):
    fcntl.ioctl(fd, 0x40045564, EV_ABS)  # UI_SET_EVBIT
    fcntl.ioctl(fd, 0x40045567, ABS_DISTANCE)  # UI_SET_ABSBIT
    setup = struct.pack("@HHHH80sI", 6, 0, 0, 1, DEVICE_NAME.encode(), 0)
    fcntl.ioctl(fd, 0x405c5503, setup)  # UI_DEV_SETUP
    limits = struct.pack("@H2xiiiiii", ABS_DISTANCE, 0, 0, 1, 0, 0, 0)
    fcntl.ioctl(fd, 0x401c5504, limits)  # UI_ABS_SETUP
    fcntl.ioctl(fd, 0x5501)  # UI_DEV_CREATE

    for _ in range(40):
        for event in Path("/sys/class/input").glob("event*"):
            try:
                if (event / "device/name").read_text().strip() == DEVICE_NAME:
                    node = Path("/dev/input") / event.name
                    if node.exists():
                        (RUNTIME / "event").unlink(missing_ok=True)
                        (RUNTIME / "event").symlink_to(node)
                        return
            except FileNotFoundError:
                continue
        time.sleep(0.05)
    raise RuntimeError("Proximity input device did not appear")


def main():
    control = RUNTIME / "enabled"
    control.write_text("0")
    with open("/dev/uinput", "wb", buffering=0) as device:
        fd = device.fileno()
        create_device(fd)
        address = os.environ["NOTIFY_SOCKET"]
        with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as notify:
            notify.sendto(b"READY=1", address.replace("@", "\0", 1) if address.startswith("@") else address)
        near = False
        while True:
            if control.read_text().strip() != "1":
                if near:
                    publish(fd, 1)
                    near = False
                time.sleep(0.15)
                continue
            try:
                level = int(RAW.read_text())
            except (OSError, ValueError):
                level = 0
            # Hysteresis keeps the display from flickering near the threshold.
            near = level >= (40 if near else 85)
            publish(fd, 0 if near else 1)
            time.sleep(0.1)


if __name__ == "__main__":
    main()
