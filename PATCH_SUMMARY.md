# Developer summary — v0.5, REVIEW ONLY, DO NOT ASSUME PUSHED

**New code**

- `scripts/instructor_diver.gd` — 3D swimming companion with simple procedural animations and route-based movement.
- `scripts/body_hud.gd` — four-body-part HP silhouette, gas leak/suit patch overlay.
- `tools/verify_cave_network.py` — branch/network and steep shaft data assertions.
- `tools/smoke_dive.gd` — test script to launch Godot worlds and damage logic in GitHub Actions.

**Edited**

- `scripts/dive_sites.gd` — first site main route & six loops/dead-end galleries; second site junction index metadata.
- `scripts/cave_builder.gd` — real multi-tube cave meshes, passable connection chambers, collision areas for spikes, stable frames for steep shafts.
- `scripts/dive_map.gd` — discoverable side branches and vertical depth chart.
- `scripts/main.gd` — tutorial, instructor radio subtitle, body health, leak repairs, safe partial extraction, modified statistics.
- `scripts/dive_audio.gd` — impact & radio chirp playback.
- `scripts/hud_glyph.gd` — patch cross pictogram.
- `tools/verify_project.py` and `.github/workflows/android.yml` — checks for new files, cave topology and headless scene smoke test.
- `README_ID.md`, `CHANGELOG.md`.

**New assets**

- `assets/audio/rock_contact.ogg`
- `assets/audio/radio_chirp.ogg`

**Preserved**

- Existing Godot/Android project structure, Android export preset, Java and SDK package selection, title/boat/lobby flow, original v0.4 textures and SFX.
- Debug APK still needs GitHub Actions build. No push has been made in this turn.
