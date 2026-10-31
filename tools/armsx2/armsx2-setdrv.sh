#!/bin/sh
# usage: armsx2-setdrv.sh <driver-id> <serial> [path-to-.so]  -- installs (if .so given) and selects a driver for one game
ID=$1 SERIAL=$2 SO=${3:-}
P=com.armsx2.nightly
adb shell am force-stop $P
if [ -n "$SO" ]; then
  adb push "$SO" /data/local/tmp/armsx2-drv.so >/dev/null
  cat > /tmp/armsx2-meta.json <<J
{"schemaVersion":1,"name":"PanVK G72 $ID","description":"test build","author":"panvk-exynos9611","packageVersion":"$ID","vendor":"Mesa","driverVersion":"$ID","minApi":31,"libraryName":"libvulkan_freedreno.so"}
J
  adb push /tmp/armsx2-meta.json /data/local/tmp/armsx2-meta.json >/dev/null
  adb shell "su -c 'D=/data/data/$P/files/drivers/$ID; U=\$(stat -c %u /data/data/$P); CTX=\$(stat -c %C /data/data/$P/files/drivers); rm -rf \$D; mkdir -p \$D; cp /data/local/tmp/armsx2-drv.so \$D/libvulkan_freedreno.so; cp /data/local/tmp/armsx2-meta.json \$D/meta.json; chown -R \$U:\$U \$D; chmod 700 \$D; chcon -R \$CTX \$D'"
fi
X=/data/data/$P/shared_prefs/ARMSX2.xml
adb shell "su -c 'cp $X /data/local/tmp/a.xml; chmod 666 /data/local/tmp/a.xml'"
adb pull /data/local/tmp/a.xml /tmp/armsx2.xml >/dev/null
python3 - "$ID" "$SERIAL" <<'PY'
import sys,re,json,html
drv,ser=sys.argv[1],sys.argv[2]
s=open('/tmp/armsx2.xml').read()
key=f'config.game.{ser}'
m=re.search(r'<string name="%s">(.*?)</string>'%re.escape(key),s)
cfg=json.loads(html.unescape(m.group(1))) if m else {}
cfg['customDriverId']=drv; cfg['renderer']='vulkan'; cfg['frameLimitEnable']=False; import os; cfg['upscaleFloat']=float(os.environ.get('UPSCALE','1'))
new='<string name="%s">%s</string>'%(key,html.escape(json.dumps(cfg,separators=(',',':')),quote=True).replace('&#x27;',"'"))
s=s.replace(m.group(0),new) if m else s.replace('</map>','    '+new+'\n</map>')
open('/tmp/armsx2.xml','w').write(s)
PY
adb push /tmp/armsx2.xml /data/local/tmp/a.xml >/dev/null
adb shell "su -c 'U=\$(stat -c %u $X); cp /data/local/tmp/a.xml $X; chown \$U:\$U $X; chmod 660 $X; restorecon $X'"
echo "selected $ID for $SERIAL"
