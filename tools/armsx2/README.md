# ARMSX2 tools

- `armsx2-setdrv.sh <driver-id> <game serial> [driver .so]` installs a build as an ARMSX2
  custom driver (root) and selects it for one game (Vulkan renderer, no frame limit).
- `bench-kh.sh <driver-id> <out>` boots Kingdom Hearts (SLUS-20370), loads save state slot 1
  and screenshots the on-screen stats 8 times (portrait tap coordinates for a 1080x2400 screen).

For frame rates without screenshots put `PANVK_FPS=1` in a `panvk.env` next to the driver
(driver 0.08+) and read `adb logcat | grep "panvk fps"`.
