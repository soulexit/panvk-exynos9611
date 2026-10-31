# Changelog

Driver versions: `0.01`, `0.02`, … The archived app repositories numbered their packages
separately (ARMSX2 0.05 wrapped driver 0.04); from 0.05 there is one number.

## 0.08 (testing) — 2026-11-01

Driver: JimVulkan/mali-panvk `d896b0a` + patches 0001–0022, reports `git-e88e525779`.

### Options file (`panvk.env`) works in every app — patch 0022

`panvk.env` holds `KEY=VALUE` lines that the driver turns into environment variables (it never
overrides one already set), for apps that offer no way to set them. Before 0.08 it was only
looked for next to the loaded library, and that was never where users put it: AdrenoTools apps
(Winlator, Eden, ARMSX2) load a *patched copy* of the driver from a `temp/` subdirectory, and
ARMSX2's loader also redirects `fopen()`. The driver now reads the first `panvk.env` found in:

1. the directory of the loaded library,
2. the directory above it (the real driver directory when loaded from `temp/`),
3. `/sdcard/Android/data/<app package>/files/`,
4. `/sdcard/Download/`,

using `open()`/`read()`. Checked in ARMSX2 (Kingdom Hearts logs `PANVK_FPS` lines).

### Measurements and guidance (no driver change)

- **Winlator ARM64EC containers are much faster.** AIO Graphics Test 2.1.0 on the A51:

  | Test | x86-64 container (Box64) | ARM64EC container (Proton 9 arm64ec, FEX) |
  |---|---|---|
  | Vulkan cube | ~400 FPS | **855–865 FPS** |
  | D3D11 cube, DXVK 2.7.1 | 460–490 (x86-64 build) | **~650** (arm64ec build; 2.6.2 the same) |
  | D3D11 cube, DXVK 2.4.1 / 1.10.3 | 550–560 / 660–670 | — |
  | D3D9 cube, DXVK 2.4.1 / 1.10.3 | 690–790 / 685–740 | — |

  The arm64ec builds of DXVK 3.1.1 and 1.14.1 crashed during DXVK's own start-up with Proton 9
  (their logs stop before adapter enumeration; the driver is never called). Use 2.6.2 or 2.7.1.
- **D3D9 vs D3D11:** on simple scenes this driver runs D3D9 as fast as D3D11 or faster (cubes
  above). Where D3D9 games are slower the cost is on the CPU: DXVK's D3D9 front end and Box64
  (the sister project measured the AIO D3D9 test at 12 FPS with Box64's *Compatibility* preset
  and 60+ with *Performance* on this phone). Use the Performance preset or an ARM64EC container.
- **ARMSX2:** Kingdom Hearts runs at full speed — 30.0 FPS, one submit per frame, 0.2 ms/s of
  submit waits; the game is CPU-bound (EE 66 %).
- **D3D12 (VKD3D-Proton):** loads in an ARM64EC container but cannot create its device yet.
  `d3d12probe` lists what is missing: `VK_EXT_mutable_descriptor_type` (device creation fails
  with `VK_ERROR_EXTENSION_NOT_PRESENT`), `robustImageAccess2` (the Mali-G72 does not
  bounds-check image coordinates, so this needs shader-side checks) and transform-feedback
  queries. Everything else VKD3D-Proton needs is present.

### Tools

`tools/winlator/wl-bench.sh` (one-command Winlator benchmark: installs a build, writes a
shortcut with the recommended settings, logs FPS and the GPU clock), `tools/winlator/d3d12probe.c`,
`tools/armsx2/` (driver install + Kingdom Hearts benchmark).

## 0.07 (testing) — 2026-11-01

Driver: patches 0001–0021, reports `git-1c4682705d`.

### DXVK 2.5 and later work — patch 0021

DXVK 2.5+ requires the Vulkan 1.2 `descriptorIndexing` feature. The driver reported it only on
Valhall, so on the Mali-G72 DXVK 2.7.1 printed *"Skipping: Device does not support required
feature 'descriptorIndexing'"*, found no GPU, and the AIO test fell back to OpenGL (Zink).

- `descriptorIndexing` and update-after-bind for every descriptor type (uniform/storage
  buffers, sampled/storage images, uniform/storage texel buffers) are now reported on v6/v7.
  Update-after-bind sets are copied into the shader tables by a GPU job at *execution* time
  (never by the faster CPU copy taken at record time), so descriptors written after binding are
  seen.
- That descriptor copy job ran **one workgroup with one thread per descriptor**. Descriptor
  indexing lets arrays hold thousands of descriptors, more threads than a workgroup may have,
  and the job failed with `DATA_INVALID_FAULT` (event 0x58). It now runs workgroups of at most
  64 threads and the shader skips the threads past the count.
- The update-after-bind limits equal the regular ones (they were 0 on Bifrost).

### Vertex pulling no longer faults the GPU — patch 0020

Ported from panvk-kirin990 (`edd369f`). Indexed and indirect draws allocate helper storage sized
by the number of vertex buffers. DXVK 2.7 binds none (it reads vertices from buffers in the
shader), the zero-sized allocation returned NULL, that was taken for out-of-memory and the
error was ignored: the draw kept a stale attribute table and job chains faulted
(`JOB_READ_FAULT`, event 0x42, 17,000+ failed atoms in 30 s).

### Results

DXVK 2.7.1 gplasync: AIO D3D11 cube 460–490 FPS, renders correctly, 0 GPU faults (did not
start before). CTS: all 115 `descriptor_indexing` cases run; 2 fail
(`uniform_texel_buffer_after_bind_in_loop`, `_lifetime`: uniform texel buffers, update-after-bind,
in a loop, vertex shader); 1,500 `binding_model` and 400 smoke cases pass.

## 0.06 (testing) — 2026-11-01

Driver: patches 0001–0019, reports `git-1af574ebf8`.

- **`PANVK_FPS=1`** (patch 0019). Every 5 s the driver logs to logcat: frames/s (render passes
  that write an imported buffer — the AHardwareBuffers that Winlator's wrapper and Android's
  WSI present), submits/s, and the CPU time spent blocked in submit-time waits and in
  sync-object waits (summed over threads). It measures FPS where the driver never sees a
  present: Winlator's wrapper has its own X11 presentation. Its count matched the AIO test's own
  counter (≈250 vs 257).
- **Winlator settings that matter** (from the sister project's study of Winlator's wrapper):
  **BCn emulation = None** — on *auto* the wrapper decodes every BC texture on the CPU for
  PanVK, although the driver handles BC itself; mailbox present mode (*immediate* gives a
  one-image swapchain); sync frame off (otherwise a full GPU drain per present); DRI3 on; Box64
  Performance preset.

## 0.05 (testing) — 2026-10-31

Driver: patches 0001–0018, reports `git-5c9141aa79`.

- **One repository and one zip.** `soulexit/panvk-exynos9611` replaces the termux, winlator and
  armsx2 repositories (archived; their history continues here). Each release has
  `panvk-g72-exynos9611-<version>.zip` (Winlator, Eden, other AdrenoTools apps, Termux) and a
  `-armsx2` zip (same driver named `libvulkan_freedreno.so`). Driver name in app lists:
  `PanVK-G72-Exynos9611-<version>`.
- **Descriptor indexing pieces on Mali-G72** (patch 0018): `descriptorBindingPartiallyBound`,
  `descriptorBindingUpdateUnusedWhilePending`, `descriptorBindingSampledImageUpdateAfterBind`.
  CTS `descriptor_indexing`: 93 pass, 0 fail at the time.

## 0.04 (testing) — 2026-10-30

Vulkan CTS fixes (patches 0006–0017): CTS failures 816 → 100 over 89,530 sampled cases, no
driver crash. Storage images in vertex shaders, null descriptors, adjacency topologies, layered
rendering and 16-bit varyings through the geometry shader emulation, kbase handle types,
zero-initialized memory, B4G4R4A4 swizzle, AHB multisampled-render-to-single-sampled.
Eden/Zelda checked after release: same as 0.03.

## 0.03 (testing) — 2026-10-28

Eden gameplay: G72 compiler fixes (no `WMASK` on v6), AFBC header init, heap 40 % of RAM, BC
emulation off in Switch emulators (patches 0003–0005).

## 0.02 (testing) — 2026-10-26

New base JimVulkan/mali-panvk `d896b0a` (Mesa 27.0.0-devel); Eden and DXVK fixes (0001–0002).

## 0.01 (testing) — 2026-10-21

First device build (Mesa 26.3.0-devel).
