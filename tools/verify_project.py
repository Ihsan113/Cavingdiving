#!/usr/bin/env python3
"""Lightweight static preflight. Requires Python 3, no external packages."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NEEDED = [
    'project.godot','export_presets.cfg','scenes/main.tscn',
    'scripts/main.gd','scripts/boat_lobby.gd','scripts/dive_sites.gd',
    'scripts/cave_builder.gd','scripts/diver.gd','scripts/dive_map.gd',
    'scripts/dive_audio.gd','scripts/hud_glyph.gd',
    'scripts/touch_joystick.gd','scripts/touch_look.gd',
    'assets/icon.png','assets/rock_limestone.png','assets/rock_normal.png',
    'assets/audio/boat_ocean.ogg','assets/audio/underwater_ambience.ogg',
    'assets/audio/regulator_breath.ogg','assets/audio/bubbles_release.ogg',
    'assets/audio/fin_swoosh.ogg','assets/audio/survey_ping.ogg',
    '.github/workflows/android.yml',
]
for name in NEEDED:
    fp = ROOT / name
    assert fp.is_file() and fp.stat().st_size, f'missing or empty: {name}'
    if name.endswith('.ogg'):
        assert fp.read_bytes()[:4] == b'OggS', f'bad Ogg: {name}'
    if name.endswith('.png'):
        assert fp.read_bytes()[:8] == b'\x89PNG\r\n\x1a\n', f'bad PNG: {name}'

for path in (ROOT/'scripts').glob('*.gd'):
    text = path.read_text(encoding='utf-8')
    for src in re.findall(r'res://([^"\']+)', text):
        # Dynamic directory prefixes are concatenated with a filename at runtime.
        if src.endswith('/'):
            assert (ROOT/src).is_dir(), f'bad resource directory in {path.name}: {src}'
        else:
            assert (ROOT/src).is_file(), f'bad resource reference in {path.name}: {src}'

cfg = (ROOT/'project.godot').read_text()
assert 'textures/vram_compression/import_etc2_astc=true' in cfg
assert 'renderer/rendering_method.mobile="gl_compatibility"' in cfg
assert 'run/main_scene="res://scenes/main.tscn"' in cfg
src = (ROOT/'scripts/main.gd').read_text()
for word in ('_show_title', '_show_lobby', '_show_briefing', '_begin_dive', 'AscendArrowButton', 'DescendArrowButton', 'TorchIconButton'):
    assert word in src, f'missing game feature: {word}'
sites = (ROOT/'scripts/dive_sites.gd').read_text()
assert 'UMBRAL CENOTE' in sites and 'BLACK KARST SYSTEM' in sites
print(f'STATIC PREFLIGHT PASSED: {len(NEEDED)} required files; valid PNG/OGG headers; scenes and assets linked')
print('NOTE: this is not a Godot parser/runtime test or verified APK build')
