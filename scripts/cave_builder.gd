extends Node3D
class_name ProceduralCave

signal sharp_rock_contact(body_part: String, damage: float)

const Sites = preload("res://scripts/dive_sites.gd")
var site_index: int = 0
var route: PackedVector3Array = PackedVector3Array()
var sample_path: PackedVector3Array = PackedVector3Array()
var branches: Array[PackedVector3Array] = []
var branch_samples: Array[PackedVector3Array] = []
var junction_positions: Array[Vector3] = []
var junction_indices: Array[int] = []
var marker_positions: Array[Vector3] = []
var marker_nodes: Array[MeshInstance3D] = []
var cave_material: StandardMaterial3D
var guide_material: StandardMaterial3D

func _ready() -> void:
    route = Sites.route_for(site_index)
    sample_path = _bake(route)
    branches = Sites.branches_for(site_index)
    for branch in branches:
        branch_samples.append(_bake(branch))
    junction_indices = Sites.junction_indices(site_index)
    for index in junction_indices:
        junction_positions.append(route[index])
    cave_material = StandardMaterial3D.new()
    cave_material.albedo_color = Color(0.73,0.80,0.78)
    cave_material.roughness = 0.98
    cave_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    cave_material.vertex_color_use_as_albedo = true
    cave_material.albedo_texture = load("res://assets/rock_limestone.png")
    cave_material.normal_enabled = true
    cave_material.normal_texture = load("res://assets/rock_normal.png")
    cave_material.normal_scale = 0.52
    guide_material = StandardMaterial3D.new()
    guide_material.albedo_color = Color(0.92,0.65,0.19)
    guide_material.roughness = 0.85
    guide_material.emission_enabled = true
    guide_material.emission = Color(0.54,0.32,0.05)
    guide_material.emission_energy_multiplier = 0.35
    _make_tunnel(sample_path,0,"MainGuidelinePassage",false)
    for branch_index in branches.size():
        _make_tunnel(branch_samples[branch_index],branch_index + 1,"SideGallery_%02d" % branch_index,true)
    for index in junction_indices:
        _make_junction_chamber(index)
    _make_guideline()
    _make_formations()
    _make_mineral_debris()
    if site_index == 0:
        _make_sharp_rocks()
    marker_positions = [sample_path[int(sample_path.size()*0.30)],sample_path[int(sample_path.size()*0.65)],sample_path[sample_path.size()-6]]
    for i in marker_positions.size():
        marker_nodes.append(_make_beacon(marker_positions[i],i))
    _make_entry_beacon()

func _bake(points: PackedVector3Array) -> PackedVector3Array:
    var curve := Curve3D.new()
    for point in points:
        curve.add_point(point)
    curve.bake_interval = 2.15
    return curve.get_baked_points()

func _near_junction(p: Vector3, distance: float = 8.1) -> bool:
    for joint in junction_positions:
        if p.distance_to(joint) < distance:
            return true
    return false

func _cave_radius(i: int, angle: float) -> float:
    # Also used by stalactites and debris; always refers to main guideline path.
    return _path_radius(i,sample_path.size(),0,angle)

func _path_radius(i: int, count: int, tunnel: int, angle: float) -> float:
    var t := float(i)/maxf(1.0,float(count-1))
    var squeeze := 0.0
    var chamber := 0.0
    var base := 3.15 if site_index == 0 else 2.85
    if tunnel > 0:
        base = 2.25 if tunnel % 2 == 0 else 2.55
        if t > 0.30 and t < 0.67:
            squeeze = -0.80 if tunnel % 2 == 0 else -0.42
        if tunnel == 5 and t > 0.47 and t < 0.70:
            chamber = 2.0
    else:
        if site_index == 0:
            if (t > 0.15 and t < 0.23) or (t > 0.47 and t < 0.55) or (t > 0.75 and t < 0.81):
                chamber = 2.7
            if (t > 0.30 and t < 0.35) or (t > 0.58 and t < 0.64) or (t > 0.89 and t < 0.94):
                squeeze = -1.38
        else:
            if (t > 0.24 and t < 0.30) or (t > 0.69 and t < 0.75): chamber = 1.42
            if (t > 0.17 and t < 0.23) or (t > 0.44 and t < 0.53) or (t > 0.77 and t < 0.84): squeeze = -1.52
    var detail := 0.23*sin(float(i)*0.27+angle*2.1)+0.13*sin(float(i)*0.79+angle*5.3)
    detail += 0.075*sin(float(i)*1.93+angle*10.7)
    return maxf(1.26,base+chamber+squeeze+detail)

func _ring_at(points: PackedVector3Array, idx: int, angle: float, tunnel: int) -> Vector3:
    var p := points[idx]
    var tangent := (points[mini(idx+1,points.size()-1)]-points[maxi(idx-1,0)]).normalized()
    # Near-vertical shafts need a different reference axis to avoid zero-length right vector.
    # Stable transported-looking reference: avoids twisting ring frames in vertical shafts.
    # Left is intentionally used so the "roof" remains upward on ordinary -Z segments.
    var ref := Vector3.LEFT if absf(tangent.dot(Vector3.LEFT)) < 0.98 else Vector3.FORWARD
    var right := (ref-tangent*ref.dot(tangent)).normalized()
    var up := tangent.cross(right).normalized()
    var width := 1.0+0.13*sin(float(idx)*0.14)
    var height := 0.93+0.13*sin(float(idx)*0.17+2.0)
    var radius := _path_radius(idx,points.size(),tunnel,angle)
    return p+right*cos(angle)*radius*width+up*sin(angle)*radius*height

func _ring_vertex(i: int, a: float) -> Vector3:
    return _ring_at(sample_path,i,a,0)

func _emit_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2, color: Color) -> void:
    st.set_color(color)
    st.set_uv(uv_a)
    st.add_vertex(a)
    st.set_color(color)
    st.set_uv(uv_b)
    st.add_vertex(b)
    st.set_color(color)
    st.set_uv(uv_c)
    st.add_vertex(c)

func _place_rock_mesh(mesh: ArrayMesh, label: String) -> void:
    if mesh == null:
        return
    var visible_mesh := MeshInstance3D.new()
    visible_mesh.name = label
    visible_mesh.mesh = mesh
    visible_mesh.material_override = cave_material
    add_child(visible_mesh)
    var body := StaticBody3D.new()
    body.name = label + "Collision"
    var collider := CollisionShape3D.new()
    var shape := mesh.create_trimesh_shape()
    if shape is ConcavePolygonShape3D:
        shape.backface_collision = true
    collider.shape = shape
    body.add_child(collider)
    add_child(body)

func _make_tunnel(points: PackedVector3Array, tunnel: int, label: String, side: bool) -> void:
    if points.size() < 2:
        return
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sectors := 16
    for i in range(points.size()-1):
        if _near_junction((points[i]+points[i+1])*0.5):
            continue
        for j in sectors:
            var a0 := TAU*float(j)/float(sectors)
            var a1 := TAU*float(j+1)/float(sectors)
            var p00 := _ring_at(points,i,a0,tunnel)
            var p01 := _ring_at(points,i,a1,tunnel)
            var p10 := _ring_at(points,i+1,a0,tunnel)
            var p11 := _ring_at(points,i+1,a1,tunnel)
            var shade := clampf(0.73+0.14*sin(float(i)*0.22+float(j)*1.3),0.49,0.94)
            var tint := Color(shade*0.74,shade*0.82,shade*0.80)
            var u0 := float(i)*0.25
            var u1 := float(i+1)*0.25
            var v0 := float(j)*3.0/float(sectors)
            var v1 := float(j+1)*3.0/float(sectors)
            _emit_triangle(st,p00,p10,p01,Vector2(u0,v0),Vector2(u1,v0),Vector2(u0,v1),tint)
            _emit_triangle(st,p10,p11,p01,Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v1),tint)
    # Main route and blind side tunnels terminate in rock, not in open empty space.
    var end_point := points[points.size()-1]
    var sealed := not _near_junction(end_point,2.0)
    if sealed:
        for j in sectors:
            var a0 := TAU*float(j)/float(sectors)
            var a1 := TAU*float(j+1)/float(sectors)
            _emit_triangle(st,end_point,_ring_at(points,points.size()-1,a1,tunnel),_ring_at(points,points.size()-1,a0,tunnel),Vector2(0.5,0.5),Vector2(1,1),Vector2(0,1),Color(0.56,0.63,0.60))
    st.generate_normals()
    st.generate_tangents()
    _place_rock_mesh(st.commit(),label)

func _junction_portals(index: int) -> Array[Vector3]:
    var p := route[index]
    var dirs: Array[Vector3] = []
    if index>0:
        dirs.append((route[index-1]-p).normalized())
    if index<route.size()-1:
        dirs.append((route[index+1]-p).normalized())
    for branch in branches:
        if branch[0].distance_to(p)<0.2:
            dirs.append((branch[1]-p).normalized())
        if branch[branch.size()-1].distance_to(p)<0.2:
            dirs.append((branch[branch.size()-2]-p).normalized())
    return dirs

func _sphere_direction(u: float, v: float) -> Vector3:
    var latitude := (v-0.5)*PI
    var longitude := u*TAU
    return Vector3(cos(latitude)*cos(longitude),sin(latitude),cos(latitude)*sin(longitude))

func _make_junction_chamber(index: int) -> void:
    var center := route[index]
    var portals := _junction_portals(index)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rows := 20
    var cols := 36
    var radius := 9.8
    for row in rows:
        for col in cols:
            var u0 := float(col)/float(cols)
            var u1 := float(col+1)/float(cols)
            var v0 := float(row)/float(rows)
            var v1 := float(row+1)/float(rows)
            var dir_mid := _sphere_direction((u0+u1)*0.5,(v0+v1)*0.5)
            var cutout := false
            for portal in portals:
                if dir_mid.dot(portal)>0.88:
                    cutout = true
                    break
            if cutout:
                continue
            var a := center+_sphere_direction(u0,v0)*radius
            var b := center+_sphere_direction(u1,v0)*radius
            var c := center+_sphere_direction(u0,v1)*radius
            var d := center+_sphere_direction(u1,v1)*radius
            var tint := Color(0.56,0.66,0.64)
            # Skip degenerate pole triangles; they can break tangent generation.
            if row > 0:
                _emit_triangle(st,a,b,c,Vector2(u0*4,v0*3),Vector2(u1*4,v0*3),Vector2(u0*4,v1*3),tint)
            if row < rows-1:
                _emit_triangle(st,b,d,c,Vector2(u1*4,v0*3),Vector2(u1*4,v1*3),Vector2(u0*4,v1*3),tint)
    st.generate_normals()
    st.generate_tangents()
    _place_rock_mesh(st.commit(),"OpenJunction_%02d" % index)
    var tag := OmniLight3D.new()
    tag.position = center+Vector3(0,4,0)
    tag.light_color = Color(0.15,0.58,0.60)
    tag.light_energy = 0.50
    tag.omni_range = 11.0
    add_child(tag)

func _make_guideline() -> void:
    var rope_mesh := CylinderMesh.new()
    rope_mesh.top_radius = 0.029
    rope_mesh.bottom_radius = 0.029
    rope_mesh.height = 1.0
    rope_mesh.radial_segments = 5
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = rope_mesh
    multi.instance_count = sample_path.size()-1
    for i in range(sample_path.size()-1):
        var a := sample_path[i]+Vector3(0,-0.95,0)
        var b := sample_path[i+1]+Vector3(0,-0.95,0)
        var d := b-a
        var basis := Basis(Quaternion(Vector3.UP,d.normalized())).scaled(Vector3(1,d.length(),1))
        multi.set_instance_transform(i,Transform3D(basis,(a+b)*0.5))
    var guide := MultiMeshInstance3D.new()
    guide.name = "MainGuideline_AlwaysReturnsToEntrance"
    guide.multimesh = multi
    guide.material_override = guide_material
    add_child(guide)

func nearest_main_index(position3: Vector3) -> int:
    var closest := 0
    var distance_squared := INF
    for i in sample_path.size():
        var d := sample_path[i].distance_squared_to(position3)
        if d < distance_squared:
            distance_squared = d
            closest = i
    return closest

func nearest_main_distance(position3: Vector3) -> float:
    return position3.distance_to(sample_path[nearest_main_index(position3)])

func nearest_branch_index(position3: Vector3) -> int:
    var closest := -1
    var distance_squared := INF
    for i in branch_samples.size():
        for p in branch_samples[i]:
            var d := p.distance_squared_to(position3)
            if d < distance_squared:
                closest = i
                distance_squared = d
    return closest

func _make_sharp_rocks() -> void:
    # Active gameplay hazards are represented by visible narrow points in traversable passages.
    var indices := [47,88,132,177,220,267,312]
    for index in indices:
        if index>=sample_path.size()-5:
            continue
        var center := sample_path[index]
        var ahead := (sample_path[index+2]-sample_path[index-2]).normalized()
        var ref := Vector3.FORWARD if absf(ahead.dot(Vector3.UP))>0.88 else Vector3.UP
        var right := ref.cross(ahead).normalized() * (1.0 if index%2==0 else -1.0)
        _place_sharp_point(center+right*1.5, -right,"ARMS" if index%3==0 else "LEGS" if index%3==1 else "TORSO",index)
    for i in [1,3,5]:
        if i>=branch_samples.size():
            continue
        var path := branch_samples[i]
        var idx := int(path.size()*0.54)
        var ahead := (path[mini(idx+2,path.size()-1)]-path[maxi(idx-2,0)]).normalized()
        var ref := Vector3.FORWARD if absf(ahead.dot(Vector3.UP))>0.88 else Vector3.UP
        var right := ref.cross(ahead).normalized()
        _place_sharp_point(path[idx]+right*1.1,-right,"HEAD" if i==3 else "ARMS",i+400)

func _place_sharp_point(at: Vector3, tip: Vector3, part: String, number: int) -> void:
    var spike := MeshInstance3D.new()
    spike.name = "JaggedRock_%d" % number
    var cone := CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 0.52
    cone.height = 2.3
    cone.radial_segments = 6
    spike.mesh = cone
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.29,0.36,0.35)
    material.roughness = 1.0
    spike.material_override = material
    spike.position = at
    spike.quaternion = Quaternion(Vector3.UP,tip.normalized())
    add_child(spike)
    var zone := Area3D.new()
    zone.name = "SharpPointContact_%d" % number
    zone.collision_layer = 2
    zone.collision_mask = 1
    zone.monitoring = true
    zone.position = at+tip.normalized()*0.84
    var shape_node := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.78
    shape_node.shape = sphere
    zone.add_child(shape_node)
    add_child(zone)
    zone.body_entered.connect(func(body: Node3D):
        if body is CaveDiver:
            sharp_rock_contact.emit(part,18.0 if part=="HEAD" else 13.0)
    )

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
