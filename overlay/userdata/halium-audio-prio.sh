#!/bin/sh
# rtkit cannot grant RT (cgroup rt_runtime=0), so give pulseaudio threads a strong nice value instead
while true; do
  for p in $(pgrep -x pulseaudio); do
    for t in /proc/$p/task/*; do renice -n -15 -p ${t##*/} >/dev/null 2>&1; done
  done
  sleep 5
done
