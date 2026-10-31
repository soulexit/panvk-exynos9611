# Eden (Switch)

Use `panvk-g72-exynos9611-<version>.zip` (the same zip as Winlator).

1. Copy the zip to the phone.
2. Eden → Settings → GPU driver manager → install the zip as it is (don't unzip it), and select it.
3. Recommended for Mali-G72: resolution 1x, VRAM usage Conservative, **GPU unswizzle off** (it
   corrupted textures with earlier builds). BC texture emulation is off by default inside Eden,
   which decodes BC itself.

Known result (driver v0.04): The Legend of Zelda: Echoes of Wisdom in-game at 6.2–6.9 FPS, no GPU
fault. The game is CPU/memory bound on a 6 GB phone.

Driver options: a `panvk.env` file next to the driver (see [DEBUGGING](../DEBUGGING.md)).
