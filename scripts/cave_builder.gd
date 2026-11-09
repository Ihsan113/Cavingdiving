extends Node3D
class_name ProceduralCave

const Sites = preload("res://scripts/dive_sites.gd")
var site_index: int = 0
var route: PackedVector3Array = PackedVector3Array()
var sample_path: PackedVector3Array = PackedVector3Array()
var marker_positions: Array[Vector3] = []
var marker_nodes: Array[MeshInstance3D] = []

var cave_material: StandardMaterial3D
var guide_material: StandardMaterial3D

func _ready() -> void:
    # Each location has its own persistent, hand-authored fictional 3D survey path.
    route = Sites.route_for(site_index)
    var curve := Curve3D.new()
    for p in route:
        curve.add_point(p)
    curve.bake_interval = 2.3
    sample_path = curve.get_baked_points()

    cave_material = StandardMaterial3D.new()
    cave_material.albedo_color = Color(0.73, 0.80, 0.78)
    cave_material.roughness = 0.98
    cave_material.metallic = 0.0
    cave_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    cave_material.vertex_color_use_as_albedo = true
    cave_material.albedo_texture = load("res://assets/rock_limestone.png")
    cave_material.normal_enabled = true
    cave_material.normal_texture = load("res://assets/rock_normal.png")
    cave_material.normal_scale = 0.52

    guide_material = StandardMaterial3D.new()
    guide_material.albedo_color = Color(0.92, 0.65, 0.19)
    guide_material.roughness = 0.85
    guide_material.emission_enabled = true
    guide_material.emission = Color(0.54, 0.32, 0.05)
    guide_material.emission_energy_multiplier = 0.35

    _make_cave_mesh()
    _make_guideline()
    _make_formations()
    _make_mineral_debris()
    marker_positions = [sample_path[int(sample_path.size() * 0.28)], sample_path[int(sample_path.size() * 0.62)], sample_path[sample_path.size() - 7]]
    for i in marker_positions.size():
        marker_nodes.append(_make_beacon(marker_positions[i], i))
    _make_entry_beacon()

func _cave_radius(i: int, angle: float) -> float:
    var t := float(i) / maxf(1.0, float(sample_path.size() - 1))
    var chamber := 1.42 if (t > 0.24 and t < 0.30) or (t > 0.69 and t < 0.75) else 0.0
    var squeeze := 0.0
    if site_index == 0:
        if (t > 0.38 and t < 0.45) or (t > 0.82 and t < 0.88):
            squeeze = -1.42
    else:
        if (t > 0.17 and t < 0.23) or (t > 0.44 and t < 0.53) or (t > 0.77 and t < 0.84):
            squeeze = -1.52
    # Continuous rock strata, not random spikes, keep restrictions navigable.
    var shape := 0.25 * sin(float(i) * 0.27 + angle * 2.1)
    shape += 0.14 * sin(float(i) * 0.79 + angle * 5.3)
    shape += 0.07 * sin(float(i) * 1.93 + angle * 10.7)
    var base := 3.25 if site_index == 0 else 2.85
    return maxf(1.12, base + chamber + squeeze + shape)

func _make_cave_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sectors := 18
    for i in range(sample_path.size() - 1):
        for j in sectors:
            var a0 := TAU * float(j) / float(sectors)
            var a1 := TAU * float(j + 1) / float(sectors)
            var p00 := _ring_vertex(i, a0)
            var p01 := _ring_vertex(i, a1)
            var p10 := _ring_vertex(i + 1, a0)
            var p11 := _ring_vertex(i + 1, a1)
            var rock_stripe := sin(float(i) * 0.19 + sin(a0) * 5.1)
            var shade := clampf(0.77 + rock_stripe * 0.10 + sin(float(i) * 1.8 + float(j) * 1.6) * 0.045, 0.52, 0.98)
            var limestone := Color(shade * 0.74, shade * 0.82, shade * 0.80)
            if sin(float(i) * 0.26 + a0 * 2.0) > 0.48:
                limestone = limestone.lerp(Color(0.41, 0.49, 0.45), 0.26)
            var u0 := float(i) * 0.24
            var u1 := float(i + 1) * 0.24
            var v0 := float(j) / float(sectors) * 3.0
            var v1 := float(j + 1) / float(sectors) * 3.0
            for vtx in [
                [p00, Vector2(u0, v0)], [p10, Vector2(u1, v0)], [p01, Vector2(u0, v1)],
                [p10, Vector2(u1, v0)], [p11, Vector2(u1, v1)], [p01, Vector2(u0, v1)]
            ]:
                st.set_color(limestone)
                st.set_uv(vtx[1])
                st.add_vertex(vtx[0])
    st.generate_normals()
    st.generate_tangents()
    st.index()
    var mesh := st.commit()
    var rock := MeshInstance3D.new()
    rock.name = "WeatheredLimestoneWalls"
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
    var width := 1.05 + 0.10 * sin(float(i) * 0.11)
    var height := 0.91 + 0.13 * sin(float(i) * 0.15 + 2.0)
    var r := _cave_radius(i, a)
    return current + right * cos(a) * r * width + up * sin(a) * r * height

func _make_guideline() -> void:
    var rope_mesh := CylinderMesh.new()
    rope_mesh.top_radius = 0.029
    rope_mesh.bottom_radius = 0.029
    rope_mesh.height = 1.0
    rope_mesh.radial_segments = 5
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = rope_mesh
    multi.instance_count = sample_path.size() - 1
    for i in range(sample_path.size() - 1):
        var a := sample_path[i] + Vector3(0, -0.95, 0)
        var b := sample_path[i + 1] + Vector3(0, -0.95, 0)
        var d := b - a
        var basis := Basis(Quaternion(Vector3.UP, d.normalized())).scaled(Vector3(1, d.length(), 1))
        multi.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
    var guide := MultiMeshInstance3D.new()
    guide.name = "FixedExpeditionGuideline"
    guide.multimesh = multi
    guide.material_override = guide_material
    add_child(guide)

func _stone_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    mat.vertex_color_use_as_albedo = true
    return mat

func _new_formation_multimesh(name: String, shape: Mesh, mat: Material, transforms: Array[Transform3D], palette: Array[Color]) -> void:
    var instance_mesh := MultiMesh.new()
    instance_mesh.transform_format = MultiMesh.TRANSFORM_3D
    instance_mesh.use_colors = true
    instance_mesh.mesh = shape
    instance_mesh.instance_count = transforms.size()
    for idx in transforms.size():
        instance_mesh.set_instance_transform(idx, transforms[idx])
        instance_mesh.set_instance_color(idx, palette[idx])
    var node := MultiMeshInstance3D.new()
    node.name = name
    node.multimesh = instance_mesh
    node.material_override = mat
    add_child(node)

func _make_formations() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 11752
    var roof_mesh := CylinderMesh.new()
    roof_mesh.top_radius = 0.40
    roof_mesh.bottom_radius = 0.012
    roof_mesh.height = 1.0
    roof_mesh.radial_segments = 7
    var floor_mesh := CylinderMesh.new()
    floor_mesh.top_radius = 0.014
    floor_mesh.bottom_radius = 0.35
    floor_mesh.height = 1.0
    floor_mesh.radial_segments = 7
    var roof_t: Array[Transform3D] = []
    var roof_c: Array[Color] = []
    var floor_t: Array[Transform3D] = []
    var floor_c: Array[Color] = []
    for i in range(7, sample_path.size() - 7, 3):
        var angle := PI * 0.5 + rng.randf_range(-0.40, 0.40)
        var roof := _ring_vertex(i, angle)
        var h := rng.randf_range(0.65, 2.05)
        var r := rng.randf_range(0.45, 1.2)
        roof_t.append(Transform3D(Basis().scaled(Vector3(r, h, r)), roof - Vector3(0, h * 0.50, 0)))
        roof_c.append(Color(rng.randf_range(0.70, 0.87), rng.randf_range(0.78, 0.93), rng.randf_range(0.74, 0.87)))
        if i % 2 == 1:
            var floor := _ring_vertex(i, PI * 1.5 + rng.randf_range(-0.55, 0.55))
            var floor_h := rng.randf_range(0.40, 1.25)
            var floor_r := rng.randf_range(0.55, 1.25)
            floor_t.append(Transform3D(Basis().scaled(Vector3(floor_r, floor_h, floor_r)), floor + Vector3(0, floor_h * 0.50, 0)))
            floor_c.append(Color(rng.randf_range(0.65, 0.80), rng.randf_range(0.74, 0.86), rng.randf_range(0.73, 0.84)))
    _new_formation_multimesh("CalciteStalactites", roof_mesh, _stone_material(Color(0.44, 0.52, 0.50)), roof_t, roof_c)
    _new_formation_multimesh("MineralStalagmites", floor_mesh, _stone_material(Color(0.39, 0.45, 0.42)), floor_t, floor_c)

func _make_mineral_debris() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 90281
    var pebble := SphereMesh.new()
    pebble.radius = 0.5
    pebble.height = 1.0
    pebble.radial_segments = 7
    pebble.rings = 4
    var transforms: Array[Transform3D] = []
    var colors: Array[Color] = []
    for i in range(4, sample_path.size() - 4, 2):
        for _j in 2:
            var bottom := _ring_vertex(i, PI * 1.5 + rng.randf_range(-0.72, 0.72))
            var sx := rng.randf_range(0.28, 1.10)
            var sy := rng.randf_range(0.18, 0.45)
            var sz := rng.randf_range(0.28, 0.95)
            transforms.append(Transform3D(Basis().scaled(Vector3(sx, sy, sz)), bottom + Vector3(0, sy * 0.20, 0)))
            var tint := rng.randf_range(0.65, 0.95)
            colors.append(Color(tint, tint * 0.98, tint * 0.91))
    _new_formation_multimesh("ScatteredFloorDebris", pebble, _stone_material(Color(0.36, 0.44, 0.42)), transforms, colors)

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
