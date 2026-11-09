# CaveDive v0.4 — Quality check

- Based on source files from v0.3 (GitHub `Ihsan113/Cavingdiving`, latest branch head inspected: `31a970e8ec51e55f30ca92937240b681cbdcfeb9`). Workflow updated locally for v0.4; not yet pushed.
- Static verification: **passed** — required project files, local references, ETC2/ASTC and GL Compatibility settings.
- `project.godot` root points to `scenes/main.tscn` and `scripts/main.gd`.
- XML/YAML syntax checks: **passed** for GitHub Actions YAML.
- Script review: balanced delimiters and nonduplicated function names across GDScript scripts, no mixed indentation.
- PNG: `icon.png`, `rock_normal.png`, `rock_limestone.png` verified.
- OGG: all 6 audio files verified with ffprobe, including generated `boat_ocean.ogg` (12 seconds).
- Route lengths calculated from `dive_sites.gd`: Umbral Cenote **508 m** one-way, max depth **31 m**. Black Karst **694 m** one-way, max depth **45 m**. Fictional paths; not georeferenced cave plans.
- 3 survey markers set near 28%, 62%, 98% of interpolated routes; must return to entry.
- All assets offline; renderer is Android GL Compatibility, ARM64-only export profile.

## Not verified yet

- Full GDScript parsing in Godot 4.7.2 runtime (no Godot executable available in this environment).
- Android APK export with v0.4 source and on-device control responsiveness/FPS.
- Geological cave mesh visual quality and all touch-screen layouts on actual phones.

Workflow includes a Godot headless startup smoke test to catch script errors before attempting APK export. **Do not label this version as a successful APK build until GitHub Actions returns success.**

## Source status

Local ZIP review package only — **no GitHub push/commit** has been performed for v0.4.
