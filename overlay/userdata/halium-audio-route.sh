#!/bin/sh
# Halium A50: set up the ABOX -> UAIF2 -> TFA9872 speaker route (the Android HAL in pulseaudio is a stub and does not)
for i in $(seq 1 30); do [ -e /dev/snd/controlC0 ] && break; sleep 1; done
python3 - <<PY
import re,subprocess
t=open("/vendor/etc/mixer_paths.xml").read()
head=t.split("<path name",1)[0]
ctls=re.findall(r"<ctl name=\"([^\"]+)\" value=\"([^\"]*)\"",head)
m=re.search(r"<path name=\"route-sifs0-to-uaif2\">(.*?)</path>",t,re.S)
if m: ctls+=re.findall(r"<ctl name=\"([^\"]+)\" value=\"([^\"]*)\"",m.group(1))
ctls+=[("SPEAKER Switch","on")]
for n,v in ctls:
    subprocess.run(["amixer","-c0","-q","cset","name="+n,v],capture_output=True)
PY
