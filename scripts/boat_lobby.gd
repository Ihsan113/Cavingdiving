extends Node3D
class_name ExpeditionBoat

var camera: Camera3D
var clock: float = 0.0

func _ready() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.18, 0.33, 0.42)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.57, 0.73, 0.76)
    env.ambient_light_energy = 0.72
    env.fog_enabled = true
    env.fog_light_color = Color(0.20, 0.40, 0.45)
    env.fog_density = 0.0025
    env_node.environment = env
    add_child(env_node)
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-32.0, -21.0, 0.0)
    sunlight.light_color = Color(1.0, 0.83, 0.61)
    sunlight.light_energy = 0.78
    sunlight.shadow_enabled = false
    add_child(sunlight)

    var water := PlaneMesh.new()
    water.size = Vector2(1800, 1800)
    water.subdivide_width = 12
    water.subdivide_depth = 12
    var sea := MeshInstance3D.new()
    sea.name = "OpenWaterHorizon"
    sea.mesh = water
    sea.material_override = _mat(Color(0.09, 0.30, 0.39), 0.35, 0.16)
    sea.position.y = -0.10
    add_child(sea)

    var hull := _mat(Color(0.09, 0.16, 0.21), 0.87, 0.08)
    var deck := _mat(Color(0.34, 0.42, 0.44), 0.94, 0.0)
    var rail := _mat(Color(0.60, 0.71, 0.73), 0.34, 0.62)
    var equipment := _mat(Color(0.06, 0.20, 0.25), 0.53, 0.24)
    var orange := _mat(Color(0.98, 0.53, 0.18), 0.65, 0.0)
    var glass := _mat(Color(0.08, 0.22, 0.30), 0.16, 0.41)
    _make_hull(hull,deck)
    _box("CenterDeckStrip",Vector3(0,1.38,-4.7),Vector3(1.25,0.025,12.0),hull)
    _box("PilotConsole",Vector3(0,2.05,-6.3),Vector3(2.35,1.20,1.5),equipment)
    _box("PilotWindow",Vector3(0,2.60,-7.0),Vector3(2.40,0.60,0.09),glass)
    _box("BridgeCanopy",Vector3(0,3.18,-6.3),Vector3(3.10,0.20,2.5),hull)
    _box("NavigationTablet",Vector3(0,2.80,-5.42),Vector3(0.94,0.52,0.10),glass)
    _box("ForwardCrate",Vector3(-1.35,1.75,-8.0),Vector3(0.8,0.82,1.18),orange)
    _box("RescueKit",Vector3(1.44,1.65,-9.3),Vector3(0.93,0.60,0.85),orange)
    for side in [-1.0,1.0]:
        _box("SideGuard",Vector3(side*2.22,1.70,-1.8),Vector3(0.10,0.55,13.8),hull)
        _tube(Vector3(side*2.16,2.42,-8.7),Vector3(side*2.16,2.42,5.0),0.045,rail)
        _tube(Vector3(side*2.16,2.42,-8.7),Vector3(side*0.4,2.42,-11.6),0.045,rail)
        for z in [-8.0,-5.0,-2.0,1.0,4.0]:
            _tube(Vector3(side*2.16,1.43,z),Vector3(side*2.16,2.43,z),0.055,rail)
        for z in [1.7,3.55]:
            var tank := CylinderMesh.new()
            tank.top_radius = 0.22
            tank.bottom_radius = 0.22
            tank.height = 1.12
            tank.radial_segments = 12
            var node := MeshInstance3D.new()
            node.mesh = tank
            node.name = "ScubaCylinder"
            node.position = Vector3(side*1.66,1.98,z)
            node.material_override = equipment
            add_child(node)
            _box("CylinderStripe",node.position+Vector3(0,0.35,0),Vector3(0.40,0.08,0.40),orange)
    _tube(Vector3(-0.4,2.42,-11.6),Vector3(0.4,2.42,-11.6),0.045,rail)
    var life_ring := TorusMesh.new()
    life_ring.inner_radius = 0.33
    life_ring.outer_radius = 0.45
    var buoy := MeshInstance3D.new()
    buoy.name = "OrangeEmergencyLifeRing"
    buoy.mesh = life_ring
    buoy.material_override = orange
    buoy.position = Vector3(1.96,2.10,-4.2)
    buoy.rotation_degrees = Vector3(90,0,90)
    add_child(buoy)

    camera = Camera3D.new()
    camera.name = "StandingOnExpeditionBoatPOV"
    camera.position = Vector3(0,2.92,5.0)
    camera.fov = 74
    camera.current = true
    add_child(camera)
    camera.look_at(Vector3(0.0,2.13,-9.5))

func _process(delta: float) -> void:
    clock += delta
    if camera != null:
        camera.position.y = 2.92 + sin(clock * 0.7) * 0.035
        camera.rotation.z = sin(clock * 0.48) * 0.003

func _make_hull(hull_material: Material, deck_material: Material) -> void:
    # Hand-built tapered bow rather than a rectangular box.
    var outline := PackedVector2Array([
        Vector2(-2.18,6.0),Vector2(2.18,6.0),Vector2(2.39,4.5),
        Vector2(2.39,-8.0),Vector2(1.8,-10.3),Vector2(0.0,-12.4),
        Vector2(-1.8,-10.3),Vector2(-2.39,-8.0),Vector2(-2.39,4.5)
    ])
    var hull_tool := SurfaceTool.new()
    hull_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in outline.size():
        var j := (i+1)%outline.size()
        var a := Vector3(outline[i].x,1.32,outline[i].y)
        var b := Vector3(outline[j].x,1.32,outline[j].y)
        var c := Vector3(outline[i].x*0.72,0.07,outline[i].y*0.97)
        var d := Vector3(outline[j].x*0.72,0.07,outline[j].y*0.97)
        for vertex in [a,b,c,b,d,c]:
            hull_tool.add_vertex(vertex)
    hull_tool.generate_normals()
    var hull_mesh := MeshInstance3D.new()
    hull_mesh.mesh = hull_tool.commit()
    hull_mesh.material_override = hull_material
    hull_mesh.name = "TaperedResearchVesselHull"
    add_child(hull_mesh)
    var deck_tool := SurfaceTool.new()
    deck_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in outline.size():
        var j := (i+1)%outline.size()
        for vertex in [Vector3(0,1.33,-2.7),Vector3(outline[i].x,1.33,outline[i].y),Vector3(outline[j].x,1.33,outline[j].y)]:
            deck_tool.add_vertex(vertex)
    deck_tool.generate_normals()
    var deck_instance := MeshInstance3D.new()
    deck_instance.mesh = deck_tool.commit()
    deck_instance.name = "NonSlipTaperedDeck"
    deck_instance.material_override = deck_material
    add_child(deck_instance)

func _mat(color: Color, rough: float, metallic_value: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metallic_value
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _box(label: String, pos: Vector3, dims: Vector3, mat: Material) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dims
    node.mesh = mesh
    node.name = label
    node.position = pos
    node.material_override = mat
    add_child(node)

func _tube(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
    var diff := b - a
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = diff.length()
    mesh.radial_segments = 7
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,diff.normalized())
    node.material_override = mat
    add_child(node)
