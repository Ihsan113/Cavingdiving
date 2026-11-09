# CaveDive v0.5 — Quality Assurance Report

## Basis

Source v0.4 was copied from the local archive. Its file list and file sizes were matched against the repository `Ihsan113/Cavingdiving` at commit `ec3250bf1355a1a326c35d3991130530af612ff4` (checked November 9, 2026). This v0.5 folder is a local review candidate, not a GitHub commit.

## Executed locally

- `python3 tools/verify_project.py` — PASS (required assets/source, resource references, PNG/OGG signatures, Android ETC2 and scene).
- `python3 tools/verify_cave_network.py` — PASS (fictional authored first map ~678m main route, six branches, three loop-backs, three blind ends, steep elevation changes, new NPC/HP logic).
- All eight OGG assets — inspected/decoded using SoundFile.
- Approximate 3D clearance analysis between new first-site side galleries and unrelated main route segments: minimum 6.8 m for side-gallery centerlines away from intended junctions; no new side-gallery centerline crossings found under 9 m. This check is geometric only, not gameplay collision validation.
- ZIP full CRC verification (conducted after archive creation).

## Configured for GitHub Actions (not executed locally)

- Godot 4.7.2 editor import and GDScript parse.
- Headless title-scene smoke test.
- `tools/smoke_dive.gd`: instantiates first and second cave worlds, instructor model, body HUD, tutorial, player rock contact damage, and seal patch logic.
- Android SDK setup, export preset, debug keystore, export APK and APK zip verification.

## Limitations

**No Godot executable or Android runtime is available in the current local environment**, so this source ZIP is NOT a verified APK, nor has it been played on a physical Android device. We cannot yet claim that every corridor junction is traversable, physics collision behavior is flawless, HUD scales on all phones, or the FPS is stable. The new smoke test is intended to catch scene/script errors when this source is built in GitHub Actions; manual playtesting remains essential.

## Suggested manual test pass on Android

1. Enter Umbral Cenote; tutorial Maya opens before control begins.
2. Observe Maya in swimming pose with her own torch; follow the yellow guideline.
3. At the first wide intersection, take a branch, return to the main line, then try a dead end.
4. Ascend the steep side chimney; test up/down controls on mobile.
5. Touch one visible rock spike; confirm body part HP and suit meter decrease, radio/impact sounds, then `SEAL SUIT` restores suit only.
6. Record one beacon, return to the entrance early, and confirm safe partial extraction.
7. Restart, record all three beacons, and return to the entrance for full completion.
8. Play Black Karst System briefly to ensure old mission is not broken.
