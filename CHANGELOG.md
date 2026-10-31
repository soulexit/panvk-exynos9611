# Changelog

Driver versions: `0.01`, `0.02`, … The archived app repositories numbered their packages
separately (ARMSX2 0.05 wrapped driver 0.04); from 0.05 there is one number.

## 0.06 (testing) — 2026-11-01

- **`PANVK_FPS=1`** (patch 0019): every 5 s the driver logs frames/s, submits/s and the CPU
  time spent blocked in waits (`adb logcat | grep "panvk fps"`). Works in Winlator, where the
  driver never sees a present (Winlator's wrapper has its own X11 presentation).
- **Winlator guide**: recommended settings — BCn emulation **None** (on *auto* the wrapper
  decodes all BC textures on the CPU for PanVK), mailbox, sync frame off, Box64 Performance —
  and first AIO Graphics Test numbers: D3D9 and D3D11 cubes both 600–700 FPS in their own
  window.
- Driver otherwise identical to 0.05.

## 0.05 (testing) — 2026-10-31

- **One repository and one zip** for Winlator, Eden, Termux, plus the same driver named for
  ARMSX2 (`-armsx2` zip). Driver name in app lists: `PanVK-G72-Exynos9611-<version>`.
- **Descriptor indexing on Mali-G72** (patch 0018): `descriptorBindingPartiallyBound`,
  `descriptorBindingUpdateUnusedWhilePending`, `descriptorBindingSampledImageUpdateAfterBind`.
  CTS `descriptor_indexing`: 93 pass, 0 fail. `descriptorIndexing` itself stays off (Bifrost
  cannot reach its limits).

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
