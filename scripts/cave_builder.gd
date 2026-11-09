extends Node3D
class_name ProceduralCave

var route: PackedVector3Array = PackedVector3Array()
var sample_path: PackedVector3Array = PackedVector3Array()
var marker_positions: Array[Vector3] = []
var marker_nodes: Array[MeshInstance3D] = []

var cave_material: StandardMaterial3D
var guide_material: StandardMaterial3D

func _ready() -> void:
    var curve := Curve3D.new()
    for p in [
        Vector3(0, -5, 5),
        Vector3(0, -7, -14),
        Vector3(6, -11, -30),
        Vector3(2, -14, -48),
        Vector3(-7, -17, -65),
        Vector3(-8, -20, -85),
        Vector3(4, -24, -108),
        Vector3(1, -27, -132),
    ]:
        route.append(p)
        curve.add_point(p)
    curve.bake_interval = 1.5
    sample_path = curve.get_baked_points()

    cave_material = StandardMaterial3D.new()
    cave_material.albedo_color = Color(0.37, 0.47, 0.50)
    cave_material.metallic = 0.04
    cave_material.roughness = 1.0
    cave_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    cave_material.vertex_color_use_as_albedo = true

    guide_material = StandardMaterial3D.new()
    guide_material.albedo_color = Color(0.96, 0.72, 0.23)
    guide_material.emission_enabled = true
    guide_material.emission = Color(0.80, 0.48, 0.10)
    guide_material.emission_energy_multiplier = 0.42

    _make_cave_mesh()
    _make_guideline()
    _make_formations()
    marker_positions = [sample_path[int(sample_path.size() * 0.32)], sample_path[int(sample_path.size() * 0.66)], sample_path[sample_path.size() - 9]]
    for i in marker_positions.size():
        marker_nodes.append(_make_beacon(marker_positions[i], i))
    _make_entry_beacon()

func _cave_radius(i: int, angle: float) -> float:
    var t := float(i) / maxf(1.0, float(sample_path.size() - 1))
    var chamber := 0.9 if (t > 0.55 and t < 0.7) or t > 0.93 else 0.0
    var noise := 0.28 * sin(float(i) * 1.67 + angle * 4.1) + 0.2 * sin(float(i) * 0.43 + angle * 7.0)
    return 3.45 + chamber + noise

func _make_cave_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sectors := 18
    var rings := sample_path.size()
    for i in (rings - 1):
        for j in sectors:
            var a0 := TAU * float(j) / float(sectors)
            var a1 := TAU * float(j + 1) / float(sectors)
            var p00 := _ring_vertex(i, a0)
            var p01 := _ring_vertex(i, a1)
            var p10 := _ring_vertex(i + 1, a0)
            var p11 := _ring_vertex(i + 1, a1)
            var shade := 0.71 + 0.17 * sin(float(i) * 0.93 + float(j) * 1.8)
            var rock_color := Color(shade * 0.65, shade * 0.81, shade * 0.82)
            # Two triangles per segment; double-sided rock material.
            for v in [p00, p10, p01, p10, p11, p01]:
                st.set_color(rock_color)
                st.add_vertex(v)
    st.generate_normals()
    var mesh := st.commit()
    var rock := MeshInstance3D.new()
    rock.name = "ExplorableLimestoneCave"
    rock.mesh = mesh
    rock.material_override = cave_material
    add_child(rock)

    var wall := StaticBody3D.new()
    wall.name = "CaveCollision"
    var col := CollisionShape3D.new()
    var collision := mesh.create_trimesh_shape()
    if collision is ConcavePolygonShape3D:
        collision.backface_collision = true
    col.shape = collision
    wall.add_child(col)
    add_child(wall)

func _ring_vertex(i: int, a: float) -> Vector3:
    var current := sample_path[i]
    var before := sample_path[maxi(0, i - 1)]
    var after := sample_path[mini(sample_path.size() - 1, i + 1)]
    var tangent := (after - before).normalized()
    var right := Vector3.UP.cross(tangent).normalized()
    var up := tangent.cross(right).normalized()
    return current + (right * cos(a) + up * sin(a)) * _cave_radius(i, a)

func _make_guideline() -> void:
    var rope := Node3D.new()
    rope.name = "FixedNavigationGuideLine"
    add_child(rope)
    var last := Vector3.ZERO
    for i in sample_path.size():
        var p := sample_path[i] + Vector3(0, -1.85, 0)
        if i > 0:
            _cylinder_between(rope, last, p, 0.035, guide_material)
        last = p

func _cylinder_between(parent: Node3D, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
    var d := b - a
    if d.length() < 0.001:
        return
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = d.length()
    cylinder.radial_segments = 5
    var mesh := MeshInstance3D.new()
    mesh.mesh = cylinder
    mesh.material_override = mat
    mesh.position = (a + b) * 0.5
    mesh.quaternion = Quaternion(Vector3.UP, d.normalized())
    parent.add_child(mesh)

func _make_formations() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 11752
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.24, 0.35, 0.37)
    stone.roughness = 1.0
    for i in range(8, sample_path.size() - 8, 7):
        var p := sample_path[i]
        var h := rng.randf_range(0.8, 2.1)
        var cone := CylinderMesh.new()
        cone.top_radius = rng.randf_range(0.32, 0.64)
        cone.bottom_radius = 0.03
        cone.height = h
        cone.radial_segments = 6
        var stalactite := MeshInstance3D.new()
        stalactite.mesh = cone
        stalactite.material_override = stone
        stalactite.position = p + Vector3(rng.randf_range(-1.2, 1.2), 3.0 - h * 0.5, 0.0)
        add_child(stalactite)

func _make_beacon(p: Vector3, index: int) -> MeshInstance3D:
    var holder := Node3D.new()
    holder.name = "SurveyBeacon_%d" % (index + 1)
    holder.position = p + Vector3(0, 0.65, 0)
    add_child(holder)
    var mesh := SphereMesh.new()
    mesh.radius = 0.43
    mesh.height = 0.86
    var visible_marker := MeshInstance3D.new()
    visible_marker.mesh = mesh
    holder.add_child(visible_marker)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.94, 0.56, 0.2)
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.49, 0.08)
    mat.emission_energy_multiplier = 2.2
    visible_marker.material_override = mat
    var glow := OmniLight3D.new()
    glow.light_color = Color(0.99, 0.68, 0.27)
    glow.light_energy = 1.4
    glow.omni_range = 7.0
    holder.add_child(glow)
    return visible_marker

func _make_entry_beacon() -> void:
    var p := route[0] + Vector3(0, 0.7, 0)
    var light := OmniLight3D.new()
    light.position = p
    light.light_color = Color(0.14, 0.92, 0.92)
    light.light_energy = 1.8
    light.omni_range = 13.0
    add_child(light)
    var ring := TorusMesh.new()
    ring.inner_radius = 0.55
    ring.outer_radius = 0.76
    var m := MeshInstance3D.new()
    m.position = p
    m.mesh = ring
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.26, 1.0, 0.95)
    mat.emission_enabled = true
    mat.emission = Color(0.11, 0.95, 0.87)
    mat.emission_energy_multiplier = 2.0
    m.material_override = mat
    add_child(m)
