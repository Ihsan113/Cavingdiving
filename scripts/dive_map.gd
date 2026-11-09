extends Control
class_name DiveMap

var route: PackedVector3Array = PackedVector3Array()
var diver_position: Vector3 = Vector3.ZERO
var diver_yaw: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var large: bool = false

func _draw() -> void:
    var bounds := Rect2(Vector2.ZERO, size)
    draw_rect(bounds, Color(0.027, 0.09, 0.13, 0.92), true)
    var center := size * 0.5
    var margin := 13.0
    for j in 5:
        var gx := margin + (size.x - 2.0 * margin) * float(j) / 4.0
        var gy := margin + (size.y - 2.0 * margin) * float(j) / 4.0
        draw_line(Vector2(gx, margin), Vector2(gx, size.y - margin), Color(0.17, 0.36, 0.4, 0.27), 1.0)
        draw_line(Vector2(margin, gy), Vector2(size.x - margin, gy), Color(0.17, 0.36, 0.4, 0.27), 1.0)
    if route.size() < 2:
        return

    # The tactical chart uses an intentionally stretched X scale for legibility.
    var xs := 0.0
    var zs := 0.0
    var min_x := INF
    var max_x := -INF
    var min_z := INF
    var max_z := -INF
    for p in route:
        min_x = minf(min_x, p.x)
        max_x = maxf(max_x, p.x)
        min_z = minf(min_z, p.z)
        max_z = maxf(max_z, p.z)
    var expand_x := maxf(9.0, max_x - min_x)
    var expand_z := maxf(10.0, max_z - min_z)
    xs = (size.x - margin * 2.0) / expand_x
    zs = (size.y - margin * 2.0) / expand_z
    var x_center := (min_x + max_x) / 2.0
    var z_center := (min_z + max_z) / 2.0

    var last := Vector2.ZERO
    for i in route.size():
        var p := route[i]
        var v := center + Vector2((p.x - x_center) * xs, (p.z - z_center) * zs)
        if i > 0:
            draw_line(last, v, Color(0.24, 0.8, 0.83, 0.75), 3.0 if large else 2.0, true)
        last = v
    var target := center + Vector2((target_position.x - x_center) * xs, (target_position.z - z_center) * zs)
    draw_circle(target, 7.0 if large else 5.0, Color(1.0, 0.75, 0.29))
    var player := center + Vector2((diver_position.x - x_center) * xs, (diver_position.z - z_center) * zs)
    draw_circle(player, 6.0 if large else 5.0, Color(0.58, 0.99, 1.0))
    var forward := Vector2(-sin(diver_yaw), -cos(diver_yaw))
    draw_line(player, player + forward * (17.0 if large else 12.0), Color.WHITE, 2.0)
    if large:
        var font := ThemeDB.fallback_font
        draw_string(font, Vector2(16.0, 26.0), "SURVEY MAP  /  TOP VIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.83, 0.98, 1.0))
        draw_string(font, Vector2(16.0, size.y - 13.0), "CYAN: GUIDE LINE    AMBER: TARGET", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.83, 0.87))
