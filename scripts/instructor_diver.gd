extends Node3D
class_name DiveInstructor

# Lightweight stylized NPC. No remote assets, networking, physics or animation system.
# Instructor leads the marked main line, and stops at junctions when player takes a side passage.
var route_points: PackedVector3Array = PackedVector3Array()
var player: CaveDiver
var _swim_clock: float = 0.0
var _left_fin: MeshInstance3D
var _right_fin: MeshInstance3D
var _ready_for_update: bool = false
var _guide_index: int = 5
var _swim_rig: Node3D

func _ready() -> void:
    name = "InstructorMaya_CompanionDiver"
    _swim_rig = Node3D.new()
    _swim_rig.name = "HorizontalSwimmingPose"
    _swim_rig.rotation_degrees.x = -78.0
    add_child(_swim_rig)
    _build_character()
    _ready_for_update = true

func _surface(color: Color, glow: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.12
    material.roughness = 0.84
    if glow:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 0.8
    return material

func _piece(label: String, mesh: Mesh, offset: Vector3, mat: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = offset
    node.material_override = mat
    _swim_rig.add_child(node)
    return node

func _box(size3: Vector3) -> BoxMesh:
    var mesh := BoxMesh.new()
    mesh.size = size3
    return mesh

func _ball(radius: float) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius*2.0
    mesh.radial_segments = 12
    mesh.rings = 6
    return mesh

func _build_character() -> void:
    var suit := _surface(Color(0.12,0.23,0.29))
    var vest := _surface(Color(0.86,0.42,0.17))
    var mask := _surface(Color(0.23,0.70,0.79),true)
    var tank := _surface(Color(0.71,0.78,0.77))
    _piece("Drysuit_Torso",_box(Vector3(0.62,0.77,0.34)),Vector3(0,0,0),suit)
    _piece("SafetyVest",_box(Vector3(0.67,0.32,0.39)),Vector3(0,0.15,-0.04),vest)
    _piece("Hood",_ball(0.25),Vector3(0,0.62,0),suit)
    _piece("DiveMask",_box(Vector3(0.36,0.18,0.08)),Vector3(0,0.64,-0.22),mask)
    for side in [-1.0,1.0]:
        _piece("Arm_%s" % side,_box(Vector3(0.20,0.76,0.22)),Vector3(side*0.44,-0.12,0),suit)
        _piece("Leg_%s" % side,_box(Vector3(0.23,0.78,0.29)),Vector3(side*0.17,-0.73,0.08),suit)
        _piece("SilverCylinder_%s" % side,_box(Vector3(0.20,0.85,0.27)),Vector3(side*0.16,0.03,0.32),tank)
    _left_fin = _piece("LeftFin",_box(Vector3(0.31,0.11,0.63)),Vector3(-0.17,-1.18,-0.23),suit)
    _right_fin = _piece("RightFin",_box(Vector3(0.31,0.11,0.63)),Vector3(0.17,-1.18,-0.23),suit)
    var light := SpotLight3D.new()
    light.name = "InstructorBackupTorch"
    light.position = Vector3(0.23,0.17,-0.24)
    light.light_color = Color(0.61,0.85,0.96)
    light.light_energy = 1.8
    light.spot_range = 16.0
    light.spot_angle = 24
    light.shadow_enabled = false
    add_child(light)

func _process(delta: float) -> void:
    if not _ready_for_update or player == null or route_points.size() < 5:
        return
    _swim_clock += delta
    _left_fin.rotation.x = sin(_swim_clock*4.0)*0.20
    _right_fin.rotation.x = sin(_swim_clock*4.0+PI)*0.20
    var best_idx := 0
    var best_dist := INF
    for i in route_points.size():
        var d := route_points[i].distance_squared_to(player.global_position)
        if d < best_dist:
            best_dist = d
            best_idx = i
    var advance := 0 if best_dist > 140.0 else 5
    var desired := mini(route_points.size()-1,best_idx+advance)
    _guide_index = clampi(_guide_index,0,route_points.size()-1)
    var waypoint_position := route_points[_guide_index]+Vector3(0,0.4,0)
    if global_position.distance_to(waypoint_position)<1.9:
        if _guide_index<desired:
            _guide_index+=1
        elif _guide_index>desired:
            _guide_index-=1
    var target := route_points[_guide_index]+Vector3(0,0.4,0)
    var offset := target-global_position
    var speed := 8.4 if offset.length()>9.0 else 5.4
    if offset.length()>0.20:
        global_position += offset.normalized()*minf(offset.length(),delta*speed)
    var look_to := (route_points[mini(_guide_index+2,route_points.size()-1)]-global_position) if _guide_index<=desired else offset
    if look_to.length_squared()>0.15:
        var flat_heading := Vector3(look_to.x,0,look_to.z)
        if flat_heading.length_squared()>0.1:
            rotation.y = lerp_angle(rotation.y,atan2(-flat_heading.x,-flat_heading.z),delta*3.0)
