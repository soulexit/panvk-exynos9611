#!/bin/sh
# wl-bench.sh <exe path on phone> <seconds> [dxvk version] [vkd3d version] [extra env]
# Install build-android/libvulkan_panfrost.so in Winlator as "PanVK-G72-dev", write a benchmark
# shortcut for container 3, run it, and print the driver's PANVK_FPS lines.
# Env: SO (driver), SHOTS (screenshot count, default 2), PRESET (box64 preset), NOINSTALL=1,
#      CONTAINER (default 3),
#      TAPS="secs:x:y ..." (screen taps after launch, in 2400x1080 coordinates), ARGS (exe arguments).
set -u
export ANDROID_SERIAL=${ANDROID_SERIAL:-RZ8N303LZFW}
EXE=$1; SECS=$2; DXVK=${3:-2.4.1-fix}; VKD3D=${4:-None}; EXTRA=${5:-}
SO=${SO:-$HOME/panvk-work/mali-panvk/build-android/libvulkan_panfrost.so}
PRESET=${PRESET:-PERFORMANCE}
PKG=com.winlator.cmod
F=/data/data/$PKG/files
DRV="$F/contents/adrenotools/PanVK-G72-dev"
C=${CONTAINER:-3}
DESK="$F/imagefs/home/xuser-$C/.wine/drive_c/users/xuser/Desktop"
OUT=${OUT:-/tmp/wlbench}; mkdir -p "$OUT"
U=$(adb shell su -c "stat -c %u $F" | tr -d '\r')

adb shell su -c "am force-stop $PKG"
# A temp/ left by the previous run makes Winlator 4.1 crash in extractGraphicsDriverFiles.
adb shell su -c "rm -rf $DRV/temp"
if [ "${NOINSTALL:-0}" != 1 ]; then
  adb push "$SO" /data/local/tmp/wl.so >/dev/null
  cat > /tmp/wl-meta.json <<JSON
{"schemaVersion":1,"name":"PanVK-G72-dev","description":"dev build","author":"soulexit","packageVersion":"0.05-dev-1","vendor":"Mesa","driverVersion":"Mesa 27.0.0-devel / PanVK-G72 dev","minApi":31,"libraryName":"libvulkan_panfrost.so"}
JSON
  adb push /tmp/wl-meta.json /data/local/tmp/wl-meta.json >/dev/null
  adb shell su -c "'mkdir -p $DRV && cp /data/local/tmp/wl.so $DRV/libvulkan_panfrost.so && cp /data/local/tmp/wl-meta.json $DRV/meta.json && chown -R $U:$U $DRV && chmod 700 $DRV && chmod 600 $DRV/*'"
fi

ENV="WRAPPER_MAX_IMAGE_COUNT=0 MESA_SHADER_CACHE_DISABLE=false MESA_SHADER_CACHE_MAX_SIZE=512MB WINEESYNC=1 PANVK_FPS=1 DXVK_HUD=fps $EXTRA"
cat > /tmp/wl-bench.desktop <<DESK
[Desktop Entry]
Name=zbench
Exec=env WINEPREFIX="/home/xuser-$C/.wine" wine "$EXE" ${ARGS:-}
Type=Application
Icon=zbench
container_id:$C

[Extra Data]
dxwrapperConfig=version=$DXVK,framerate=0,async=0,asyncCache=0,maxFrameLatency=0,vkd3dVersion=$VKD3D,vkd3dLevel=12_1,ddrawrapper=none,csmt=3,gpuName=NVIDIA GeForce GTX 480,videoMemorySize=2048,strict_shader_math=1,OffscreenRenderingMode=fbo,renderer=gl
envVars=$ENV
graphicsDriverConfig=vulkanVersion=1.4;version=PanVK-G72-dev;blacklistedExtensions=;maxDeviceMemory=0;presentMode=mailbox;syncFrame=0;disablePresentWait=0;timelineSemaphores=0;resourceType=auto;bcnEmulation=none;bcnEmulationType=compute;bcnEmulationCache=0;gpuName=Device
box64Preset=$PRESET
box64Version=0.4.4
rendererNative=0
useDisplayX=0
rendererPresentMode=fifo
surfaceFormat=bgra8
DESK
adb push /tmp/wl-bench.desktop /data/local/tmp/zbench.desktop >/dev/null
adb shell su -c "'cp /data/local/tmp/zbench.desktop $DESK/zbench.desktop && chown $U:$U $DESK/zbench.desktop'"

adb logcat -c
adb logcat -v time > "$OUT/logcat.txt" 2>/dev/null &
LC=$!
adb shell su -c "am start -n $PKG/.XServerDisplayActivity --ei container_id $C --es shortcut_path $DESK/zbench.desktop" >/dev/null
for t in ${TAPS:-}; do
  ( d=${t%%:*}; xy=${t#*:}; sleep "$d"; adb shell input tap "${xy%%:*}" "${xy#*:}" ) &
done
( n=0; while [ $n -lt $((SECS / 5)) ]; do
    echo "$(date +%s) $(adb shell su -c 'cat /sys/class/misc/mali0/device/clock' | tr -d '\r')"; sleep 5; n=$((n + 1))
  done > "$OUT/clock.txt" ) &
N=${SHOTS:-2}; i=0; step=$((SECS / N))
while [ $i -lt $N ]; do
  sleep $step; i=$((i + 1))
  adb exec-out screencap -p > "$OUT/shot$i.png"
done
kill $LC 2>/dev/null
adb shell su -c "am force-stop $PKG"
grep -E "panvk fps" "$OUT/logcat.txt" | sed 's/^.*panvk fps: //'
awk '{print $2}' "$OUT/clock.txt" | sort -n | uniq -c | sort -rn | head -4 | tr '\n' ' ' | sed 's/^/gpu clock samples (count MHz): /'; echo
grep -cE "event code|kbase: |panvk: the kbase" "$OUT/logcat.txt" | sed 's/^/driver error lines: /'
