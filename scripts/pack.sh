#!/bin/sh
# pack.sh <libvulkan_panfrost.so> <version> [outdir] — the release zips:
#   panvk-g72-exynos9611-<version>.zip         Winlator, Eden, other AdrenoTools apps, Termux
#   panvk-g72-exynos9611-<version>-armsx2.zip  ARMSX2 (library named libvulkan_freedreno.so)
# The driver name has no spaces: apps unpack the zip into a directory of that name.
set -eu
SO="$1"; VER="$2"; OUT="${3:-dist}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
for LAYOUT in main armsx2; do
  LIB=libvulkan_panfrost.so; SUFFIX=""
  if [ "$LAYOUT" = armsx2 ]; then LIB=libvulkan_freedreno.so; SUFFIX=-armsx2; fi
  T="$(mktemp -d)"
  cp "$SO" "$T/$LIB"
  cp "$ROOT/LICENSE" "$ROOT/NOTICE.md" "$T/"
  if [ "$LAYOUT" = main ]; then
    cp "$ROOT/scripts/install-termux.sh" "$T/"
    cp "$ROOT/icd/panvk-exynos9611.json.in" "$T/panvk-exynos9611.json"
  fi
  cat > "$T/meta.json" <<JSON
{
  "schemaVersion": 1,
  "name": "PanVK-G72-Exynos9611-$VER",
  "description": "Mesa PanVK over the stock mali_kbase/JM driver for Mali-G72 MP3 (Samsung Galaxy A51 / Exynos 9611). Geometry/tessellation/transform feedback emulation, robustness2. Testing build.",
  "author": "soulexit",
  "packageVersion": "$VER",
  "vendor": "Mesa",
  "driverVersion": "Mesa 27.0.0-devel / PanVK-kbase G72-Exynos9611 $VER",
  "minApi": 31,
  "libraryName": "$LIB"
}
JSON
  (cd "$T" && sha256sum "$LIB" > SHA256SUMS)
  ZIP="$OUT/panvk-g72-exynos9611-$VER$SUFFIX.zip"
  rm -f "$ZIP"
  (cd "$T" && zip -q -r "$ZIP" .)
  rm -rf "$T"
  sha256sum "$ZIP"
done
