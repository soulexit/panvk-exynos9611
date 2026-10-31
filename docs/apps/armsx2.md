# ARMSX2

Use `panvk-g72-exynos9611-<version>-armsx2.zip` (same driver; ARMSX2 requires the library to be named `libvulkan_freedreno.so`).

## Install

### Option A — import in ARMSX2 (no root, recommended)

1. Download `panvk-g72-exynos9611-<version>-armsx2.zip` from [Releases](https://github.com/soulexit/panvk-exynos9611/releases).
2. Copy it to the phone.
3. Open **ARMSX2 → Settings → Renderer** and set **Graphics API** to **Vulkan**.
4. Open **GPU Driver → Import** (the section appears after Vulkan is selected) and choose the zip.
5. Select **PanVK Exynos 9611 (Mali-G72 MP3)**.
6. Start the game with the Vulkan renderer.
7. On first failure, switch back to **System Vulkan driver** and collect the logs.

The importer requires `meta.json` and `libvulkan_freedreno.so` at the **zip root**. If you get
"it needs to be an AdrenoToolsDrivers-style .zip", the archive layout is wrong or the download is
truncated.

### Option B — adb push, then import

```sh
./scripts/install-adb.sh
```

The zip is copied to `/sdcard/Download/`; import it from the app. No root needed.

### Option C — direct install (root, advanced)

```sh
./scripts/install-adb.sh --root --yes
```

Copies the unpacked driver into ARMSX2's private storage. The exact directory differs between
nightly and stable packages; the script detects the installed package and prints what it did.
Force-stop ARMSX2 afterwards. Prefer the in-app importer.

## Uninstall / revert

- Select **System Vulkan driver** in ARMSX2's GPU driver settings.
- Remove the imported driver from the same screen.
- Root install: remove the directory printed by the installer, then restart ARMSX2.

The vendor Vulkan driver is untouched.

## Testing

1. Start with a light PS2 game at native resolution (no upscaling, no widescreen patches).
2. Use the **Vulkan** renderer.
3. If it boots, reach gameplay before recording a result.
4. Capture:
   - ARMSX2 version and settings (renderer, resolution, upscaler, frame limit);
   - `adb logcat -d -s panvk:* Mesa:* AndroidRuntime:E > logcat.txt`;
   - `adb shell dmesg | grep -iE 'mali|kbase|gpu|fault' > dmesg.txt`;
   - a screenshot of the emulator log overlay if it shows a Vulkan feature error.
5. Fill in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md).

```sh
./scripts/collect-logs.sh
```

## Known limitations

- **Mali-G72 v6 is the least-tested Bifrost path.** The base tree validated G72 on a Galaxy Tab S6
  Lite; the A51's Android 16 + kbase r38 is new.
- **ARMSX2 custom drivers are Adreno-oriented.** Listing/selecting a Mali ICD is not guaranteed by
  the app. Treat this repository as an experiment with a clear log trail.
- **No D3D12/vkd3d-proton.** Irrelevant for PS2 emulation. BCn is emulated since driver v0.02 but
  PS2 games do not use it.
- **Kingdom Hearts is EE-bound** on this SoC (EE 100% uncapped): driver changes do not move its
  frame rate; GS thread time is the same on driver v0.01 and v0.02.
- **GS/tessellation/XFB are compute-emulated** and slow on three G72 cores.
- **Shared RAM.** PS2 emulation plus a Vulkan driver on a 6 GB phone leaves little headroom.
- **Android 16 gralloc** can break presentation while offscreen rendering works.

## Debugging

| Switch | Effect |
|---|---|
| `PANVK_DEBUG=startup` | Device-creation diagnostics |
| `PANVK_DEBUG=trace` | Verbose tracing |
| `PANVK_FORCE_IDVS=1` | Re-enable index-driven vertex shading |

ARMSX2 may not expose environment variables to the driver. Use logcat first:

```sh
adb logcat -d -s 'panvk:*' 'Mesa:*' 'AndroidRuntime:E'
adb shell 'dmesg | grep -iE "mali|kbase|gpu|fault|mmu"'
```

See [`docs/DEBUGGING.md`](docs/DEBUGGING.md) for the app-specific checks and the generic kbase
failure classes.

