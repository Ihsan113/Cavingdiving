extends RefCounted
class_name CaveDiveSites

# Original, fictional routes influenced by real limestone / karst geology.
# Not measured surveys of real caves; never use for navigation in real life.

static func title(site: int) -> String:
    return "UMBRAL CENOTE" if site == 0 else "BLACK KARST SYSTEM"

static func location(site: int) -> String:
    return "YUCATAN-INSPIRED / LIMESTONE" if site == 0 else "TROPICAL KARST-INSPIRED / DEEP RESTRICTIONS"

static func description(site: int) -> String:
    if site == 0:
        return "Long eroded passages, mineral curtains and a broad twilight chamber. A good first expedition with two tight squeezes."
    return "Extended bends, darker stone, more restrictions, and deceptive side galleries. For experienced virtual explorers."

static func route_for(site: int) -> PackedVector3Array:
    if site == 0:
        return PackedVector3Array([
            Vector3(0, -7, 8), Vector3(0, -9, -25),
            Vector3(11, -12, -59), Vector3(24, -14, -96),
            Vector3(18, -16, -133), Vector3(1, -19, -166),
            Vector3(-18, -22, -199), Vector3(-9, -24, -235),
            Vector3(14, -26, -274), Vector3(34, -28, -313),
            Vector3(26, -30, -352), Vector3(1, -29, -386),
            Vector3(-17, -28, -425), Vector3(-8, -31, -459)
        ])
    return PackedVector3Array([
        Vector3(0, -11, 8), Vector3(-8, -13, -29),
        Vector3(-23, -18, -69), Vector3(-11, -22, -107),
        Vector3(16, -25, -145), Vector3(32, -30, -185),
        Vector3(14, -33, -223), Vector3(-18, -35, -263),
        Vector3(-38, -37, -307), Vector3(-20, -40, -352),
        Vector3(11, -42, -394), Vector3(38, -43, -437),
        Vector3(20, -45, -477), Vector3(-12, -43, -521),
        Vector3(-28, -41, -560), Vector3(-4, -44, -603)
    ])

static func branches_for(site: int) -> Array[PackedVector3Array]:
    var r := route_for(site)
    if site == 0:
        return [
            PackedVector3Array([r[4], r[4] + Vector3(19,-2,-15), r[4] + Vector3(32,-3,-29)]),
            PackedVector3Array([r[9], r[9] + Vector3(-22,-1,-12), r[9] + Vector3(-35,-2,-26)])
        ]
    return [
        PackedVector3Array([r[3], r[3] + Vector3(27,-3,-11), r[3] + Vector3(44,-5,-27)]),
        PackedVector3Array([r[8], r[8] + Vector3(-18,-2,-17), r[8] + Vector3(-26,-4,-31)]),
        PackedVector3Array([r[12], r[12] + Vector3(25,-1,-14), r[12] + Vector3(39,0,-32)])
    ]

static func distance_m(site: int) -> int:
    var r := route_for(site)
    var distance := 0.0
    for i in range(1, r.size()):
        distance += r[i].distance_to(r[i - 1])
    return int(roundf(distance))

static func depth_m(site: int) -> int:
    var maximum := 0.0
    for p in route_for(site):
        maximum = maxf(maximum, -p.y)
    return int(ceilf(maximum))
