#!/bin/sh
# usage: bench-kh.sh <driver-id> <outprefix>  -- boots KH, loads slot 1, samples the OSD 8x
ID=$1 OUT=$2
~/panvk-work/armsx2-setdrv.sh "$ID" SLUS-20370 >/dev/null
sleep 20   # let the SoC cool a bit between runs
adb shell am start -n com.armsx2.nightly/com.armsx2.BootSplashActivity >/dev/null; sleep 6
adb shell input tap 186 1230; sleep 40          # KH cover in library
adb shell input tap 898 134; sleep 2            # pause menu
adb shell input swipe 540 2000 540 600 400; sleep 1
adb shell input tap 798 2224; sleep 3           # LOAD
adb shell input tap 282 1680; sleep 8           # slot 1
for i in 1 2 3 4 5 6 7 8; do adb exec-out screencap -p > /tmp/${OUT}_$i.png; sleep 3; done
python3 - "$OUT" <<'PY'
import sys
from PIL import Image
o=sys.argv[1]
ims=[Image.open(f'/tmp/{o}_{i}.png').crop((440,0,1080,340)).resize((480,255)) for i in range(1,9)]
out=Image.new('RGB',(480*2,255*4))
for k,im in enumerate(ims): out.paste(im,((k%2)*480,(k//2)*255))
out.save(f'/tmp/{o}.png')
PY
adb logcat -d | grep -m3 -E "VK: GPU '" | cut -c1-200
