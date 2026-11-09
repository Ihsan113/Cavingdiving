#!/usr/bin/env python3
"""Test the authored fictional cave data without requiring Godot on local host."""
from pathlib import Path
import math
import re

root = Path(__file__).resolve().parent.parent
source = (root/'scripts/dive_sites.gd').read_text()
block = source.split('static func route_for(site: int)',1)[1].split('return PackedVector3Array([',1)[1].split('])',1)[0]
vec_pattern = re.compile(r'Vector3\(([^)]+)\)')
parse = lambda z: tuple(float(x.strip()) for x in z.split(','))
main = [parse(i) for i in vec_pattern.findall(block)]
assert len(main) >= 17, f'route too short: {len(main)}'
length = sum(math.dist(a,b) for a,b in zip(main,main[1:]))
assert length >= 620, f'main route too short: {length:.0f}m'
assert max(-p[1] for p in main) >= 45, 'no deep segments'
slopes = [math.degrees(math.atan2(abs(a[1]-b[1]), math.hypot(a[0]-b[0],a[2]-b[2]))) for a,b in zip(main,main[1:])]
assert sum(deg>=50 for deg in slopes)>=2, f'no vertical passages: {slopes}'

branches_block = source.split('static func branches_for(site: int)',1)[1].split('if site == 0:',1)[1].split('return [',1)[1].split('\n        ]',1)[0]
branch_lines = [s.strip() for s in branches_block.splitlines() if 'PackedVector3Array([' in s]
assert len(branch_lines)==6, f'expected six galleries: {len(branch_lines)}'
loops = 0
blind = 0
steep_branch = False
for line in branch_lines:
    exprs = re.findall(r'r\[\d+\]|Vector3\([^)]+\)',line)
    points=[]
    for expr in exprs:
        points.append(main[int(expr[2:-1])] if expr.startswith('r[') else parse(expr[8:-1]))
    assert len(points)>=4
    assert points[0] in main, 'side gallery must open at main route'
    if points[-1] in main:
        loops+=1
    else:
        blind+=1
    for a,b in zip(points,points[1:]):
        h=math.hypot(a[0]-b[0],a[2]-b[2])
        if math.degrees(math.atan2(abs(a[1]-b[1]),h))>=63:
            steep_branch=True
assert loops>=3 and blind>=3, f'expected loops and deadends, got loops={loops}, blind={blind}'
assert steep_branch,'chimney is not steep enough'

cave=(root/'scripts/cave_builder.gd').read_text()
for symbol in ['_make_tunnel(branch_samples','_make_junction_chamber','_make_sharp_rocks','sharp_rock_contact.emit','_junction_portals','_near_junction']:
    assert symbol in cave, f'missing structural geometry {symbol}'
main_code=(root/'scripts/main.gd').read_text()
for symbol in ['_on_sharp_rock_contact','_seal_suit','_show_training','_set_comm','body_display','instructor','found_branches']:
    assert symbol in main_code, f'missing mechanic {symbol}'
print(f'NETWORK PREFLIGHT PASSED: {length:.0f}m primary path, {len(branch_lines)} 3D side galleries, {loops} return loops, {blind} dead ends, steep shafts, collision hazards and NPC trainer')
