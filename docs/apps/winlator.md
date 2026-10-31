# Winlator

Use `panvk-g72-exynos9611-<version>.zip`. Tested with `com.winlator.cmod` 4.1.

## Recommended settings

**Prefer an ARM64EC container** (Settings → Containers → +, Wine *Proton 9 arm64ec*) with the
arm64ec builds of DXVK: Windows code then runs natively through FEX's ARM64EC mode instead of
Box64. AIO Graphics Test on the A51: Vulkan cube 855–865 FPS vs ~400 in the x86-64 container,
D3D11 cube ~650 FPS (DXVK 2.6.2 / 2.7.1 arm64ec) vs 470–560. In ARM64EC containers DXVK 3.1.1
and 1.14.1 (arm64ec builds) crashed during their own start-up with Proton 9; use 2.6.2 or
2.7.1.

Settings for any container:

In the container (or the shortcut's own settings):

| Setting | Value | Why |
|---|---|---|
| Graphics driver | `PanVK-G72-Exynos9611-<version>` | |
| **BCn emulation** | **None** | On *auto* Winlator's wrapper decodes every BC texture on the CPU for PanVK, although the Mali-G72 path samples BC itself: slower, more memory, and wrong copies |
| Present mode | mailbox (default) | *immediate* makes Winlator use a one-image swapchain |
| Sync frame | off | on, the wrapper waits for the GPU to go idle at every present |
| Use DRI3 | on (default) | off, presents go through CPU copies with a full wait each |
| Box64 preset | **Performance** | D3D9 AIO test: 12 FPS on Compatibility, 60+ on Performance (Box64's memory barriers, not the driver) |
| DXVK | 1.10.3, 2.4.1, 2.7.1 gplasync (0.07+) measured here | DXVK 2.5+ needs driver 0.07 or newer. arm64ec builds of DXVK/VKD3D need an ARM64EC container |

Measuring FPS without the on-screen HUD: put `PANVK_FPS=1` in the container's environment
variables and read `panvk fps:` lines from `adb logcat` (frames/s, submits/s, CPU wait time).

## Measured (driver 0.06, AIO Graphics Test 2.1.0, 64-bit, DXVK 2.4.1, Box64 Performance)

| Test | FPS |
|---|---|
| AIO main window, Direct3D 11 cube | ~250 |
| `--cube dx11` (standalone window) | 460–610 |
| `--cube dx9` (standalone window) | 620–700 |
| `--cube dx11`, DXVK 2.7.1 gplasync (0.07) | 460–490 |
| `--cube dx9`, DXVK 1.10.3 | 685–740 |
| `--cube vk` | ~400 |

## Install

### Option A — import the zip in Winlator (no root, recommended)

1. Download `panvk-g72-exynos9611-<version>.zip` from
   [Releases](https://github.com/soulexit/panvk-exynos9611/releases).
2. Copy it to the phone (Downloads is fine).
3. Open **Winlator → Contents → AdrenoTools** (the driver manager).
4. Tap **Install / Import**, choose the zip, wait for it to appear under **Available Drivers**.
5. Open the container → **Graphics / Vulkan** settings → select
   **PanVK Exynos 9611 (Mali-G72 MP3)**.
6. Start with `vkcube.exe` or a light D3D9 game. Do not start with a heavy D3D11 title.

If Winlator shows an import error, check that the zip has `meta.json` and
`libvulkan_panfrost.so` at the **root**, not inside a folder.

### Option B — push with adb, then import

```sh
./scripts/install-adb.sh
```

This copies the zip to `/sdcard/Download/` and prints the import path. It does not silently modify
Winlator's data directory.

### Option C — direct install (root, advanced)

```sh
./scripts/install-adb.sh --root --yes
```

Requires a working `su` for the shell. The script copies the unpacked driver to:

```text
/data/data/com.winlator.cmod/files/contents/adrenotools/PanVK-Exynos9611-v0.04/
```

Force-stop Winlator before and after. Use this only when the in-app importer is unavailable; the
normal import path is safer and survives app updates better.

## Uninstall / revert

- In Winlator, select **System Vulkan driver** in the container settings.
- Delete the imported driver entry from the AdrenoTools list.
- Root install: remove the folder under
  `/data/data/com.winlator.cmod/files/contents/adrenotools/` and restart Winlator.

The vendor Vulkan driver is never modified.

## Test procedure

1. Select the driver in the container.
2. Run `vkcube.exe` first (DXVK D3D11, tiny workload).
3. If that works, run a D3D9 game at 800×600 or 1280×720, not native 1080p.
4. Capture:
   - Winlator container settings (DXVK version, Box64/FEX, resolution, GPU driver);
   - `adb logcat -d -s panvk:* Mesa:* AndroidRuntime:E > logcat.txt`;
   - `adb shell dmesg | grep -iE 'mali|kbase|gpu|fault' > dmesg.txt`;
   - a screenshot of the DXVK HUD if it is enabled.
5. Fill in [`docs/TEST-RESULTS.md`](docs/TEST-RESULTS.md) or the report template.

```sh
./scripts/collect-logs.sh
```

## Known limitations

- **Mali-G72 is Mesa v6 Bifrost**, the least-tested Bifrost path. The base tree validated G72 on a
  Galaxy Tab S6 Lite (same SoC family); the A51's Android 16 + kbase r38 is a new combination.
- **BCn is emulated by the driver** (v0.02+). If textures look wrong, set the container's BCn
  emulation to the wrapper's, or put `PANVK_NO_BC_EMU=1` in `panvk.env` next to the driver.
- **No D3D12 / vkd3d-proton.** The required Vulkan features are not there yet.
- **GS/tessellation/XFB are compute-emulated.** On a 3-core G72 this is slow; expect D3D9 and light
  D3D11 only.
- **Shared memory.** On a 6 GB phone, Wine + DXVK + a game can exhaust RAM; close background apps.
- **First frame / shader compilation** can take seconds; a black screen for a few seconds is not
  necessarily a crash.
- **Android 16 gralloc** may break swapchain presentation; offscreen tests can pass while the
  window stays black.

## Debugging

| Switch | Effect |
|---|---|
| `PANVK_DEBUG=startup` | Device-creation diagnostics |
| `PANVK_DEBUG=trace` | Verbose tracing |
| `PANVK_FORCE_IDVS=1` | Re-enable index-driven vertex shading |
| `MESA_LOG=stderr` | Send Mesa logs to stderr |

Winlator does not give the driver a shell, so set these through the container's environment field if
it exposes one, or use a debug build with the switch compiled in. Logs land in logcat under `panvk`
and `Mesa`.

See [`docs/DEBUGGING.md`](docs/DEBUGGING.md) for the failure classes that matter on this device:
atom stride / `JOB_CONFIG_FAULT`, `VK_ERROR_DEVICE_LOST`, black swapchain, and app-side driver
loading.


## D3D12 (VKD3D-Proton)

Not working yet. VKD3D-Proton loads, but needs `VK_EXT_mutable_descriptor_type`,
`robustImageAccess2` and transform-feedback queries, which this driver does not provide yet.
