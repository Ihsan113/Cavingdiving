extends RefCounted
class_name CaveDiveSites

# Original game-only fictional cave networks. NOT authentic cave surveys or dive-planning data.
# The principal route connects 3 survey beacons. Side tunnels may loop or dead-end.
static func title(site: int) -> String:
    return "UMBRAL CENOTE" if site == 0 else "BLACK KARST SYSTEM"

static func location(site: int) -> String:
    return "YUCATAN-INSPIRED / LIMESTONE" if site == 0 else "TROPICAL KARST-INSPIRED / DEEP RESTRICTIONS"

static func description(site: int) -> String:
    if site == 0:
        return "A genuine branching 3D maze: vertical shafts, lost galleries, narrow restrictions and cathedral chambers. Stay close to instructor and guideline."
    return "A remote karst passage with darker water and narrow restrictions. Original route preserved for this update."

static func route_for(site: int) -> PackedVector3Array:
    if site == 0:
        return PackedVector3Array([
            Vector3(0,-7,8), Vector3(0,-10,-25), Vector3(12,-17,-56),
            Vector3(26,-25,-88), Vector3(36,-13,-120), Vector3(20,-9,-152),
            Vector3(-4,-16,-183), Vector3(-10,-35,-195), Vector3(-11,-43,-247),
            Vector3(10,-31,-279), Vector3(28,-33,-311), Vector3(30,-12,-324),
            Vector3(25,-26,-374), Vector3(2,-39,-406), Vector3(-19,-47,-438),
            Vector3(-34,-30,-468), Vector3(-18,-19,-499), Vector3(6,-35,-530),
            Vector3(21,-43,-563)
        ])
    return PackedVector3Array([
        Vector3(0,-11,8), Vector3(-8,-13,-29), Vector3(-23,-18,-69),
        Vector3(-11,-22,-107), Vector3(16,-25,-145), Vector3(32,-30,-185),
        Vector3(14,-33,-223), Vector3(-18,-35,-263), Vector3(-38,-37,-307),
        Vector3(-20,-40,-352), Vector3(11,-42,-394), Vector3(38,-43,-437),
        Vector3(20,-45,-477), Vector3(-12,-43,-521), Vector3(-28,-41,-560),
        Vector3(-4,-44,-603)
    ])

static func branches_for(site: int) -> Array[PackedVector3Array]:
    var r := route_for(site)
    if site == 0:
        return [
            # 01 alternative route joins the main line again; more vertical elevation.
            PackedVector3Array([r[3],Vector3(42,-13,-105),Vector3(58,-8,-134),Vector3(41,-17,-161),r[6]]),
            # 02 chimney climbs sharply and ends in a blind dome.
            PackedVector3Array([r[7],Vector3(-17,-33,-202),Vector3(-18,-18,-207),Vector3(-19,-7,-212),Vector3(-43,-5,-239)]),
            # 03 deep squeeze returns to the lower tunnel after a dramatic drop.
            PackedVector3Array([r[9],Vector3(37,-36,-300),Vector3(55,-48,-324),Vector3(51,-31,-359),r[12]]),
            # 04 unmarked twisting blind corridor.
            PackedVector3Array([r[11],Vector3(60,-18,-361),Vector3(73,-27,-380),Vector3(67,-39,-402)]),
            # 05 high gallery loops into the main line.
            PackedVector3Array([r[14],Vector3(-49,-32,-446),Vector3(-56,-17,-470),Vector3(-37,-12,-487),r[16]]),
            # 06 narrow blind terminal, only one way out.
            PackedVector3Array([r[17],Vector3(35,-32,-540),Vector3(49,-28,-557),Vector3(57,-22,-576)])
        ]
    return [
        PackedVector3Array([r[3],r[3]+Vector3(27,-3,-11),r[3]+Vector3(44,-5,-27)]),
        PackedVector3Array([r[8],r[8]+Vector3(-18,-2,-17),r[8]+Vector3(-26,-4,-31)]),
        PackedVector3Array([r[12],r[12]+Vector3(25,-1,-14),r[12]+Vector3(39,0,-32)])
    ]

static func junction_indices(site: int) -> Array[int]:
    return [3,6,7,9,11,12,14,16,17] if site == 0 else [3,8,12]

static func branch_names(site: int) -> Array[String]:
    if site == 0:
        return ["SKYLIGHT LOOP", "BLIND CHIMNEY", "DEEP SQUEEZE", "FALSE EXIT", "CATHEDRAL LOOP", "DEAD-END RESTRICTION"]
    return ["MINERAL GALLERY", "SIDE POCKET", "DARK PASSAGE"]

static func distance_m(site: int) -> int:
    var r := route_for(site)
    var dist := 0.0
    for i in range(1,r.size()):
        dist += r[i].distance_to(r[i-1])
    return int(roundf(dist))

static func depth_m(site: int) -> int:
    var maximum := 0.0
    for p in route_for(site):
        maximum = maxf(maximum,-p.y)
    for branch in branches_for(site):
        for p in branch:
            maximum = maxf(maximum,-p.y)
    return int(ceilf(maximum))
