# Winlator benchmark tools

`wl-bench.sh <exe on phone> <seconds> [dxvk version] [vkd3d version] [extra env]` installs
`build-android/libvulkan_panfrost.so` (or `SO=`) in Winlator as the driver `PanVK-G72-dev`, writes a
`zbench` shortcut in a container (`CONTAINER=`, default 3) with the recommended settings (BCn
emulation None, mailbox, sync frame off, Box64 `PRESET=`), runs it, and prints the driver's
`PANVK_FPS` lines and the GPU clock (sampled with root). `ARGS=` passes arguments to the exe.
Needs adb with root on the phone.

Notes from writing it:

- Winlator 4.1 (Ludashi) crashes in `extractGraphicsDriverFiles` if the driver's `meta.json`
  `packageVersion` doesn't have three `-` separated parts, or if a `temp/` directory is left in
  the driver directory from an earlier run (the script removes it).
- Taps don't reach the X session (the touchscreen is a trackpad); the AIO Graphics Test has a
  command line instead: `--cube dx9|dx11|dx12|vk`, `--scene drawstress --draws N`, `--bench N`.
- The DXVK/VKD3D versions are Winlator's content names (e.g. `2.7.1-gplasync`,
  `3.0.1-arm64ec`); arm64ec builds need an ARM64EC container.

`d3d12probe.c` (from [panvk-kirin990](https://github.com/soulexit/panvk-kirin990)) checks a
driver against VKD3D-Proton's hard requirements:
`aarch64-linux-android31-clang -I<mesa>/include -o d3d12probe d3d12probe.c -ldl`, then run
`d3d12probe <path to libvulkan_panfrost.so>` on the phone.
