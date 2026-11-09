extends Control
class_name DiveJoystick

var touch_id: int = -1
var direction: Vector2 = Vector2.ZERO
var active: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch:
        if event.pressed and touch_id == -1 and get_global_rect().has_point(event.position):
            touch_id = event.index
            active = true
            _update_axis(event.position)
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            active = false
            direction = Vector2.ZERO
            queue_redraw()
    elif event is InputEventScreenDrag and event.index == touch_id:
        _update_axis(event.position)

func _update_axis(touch_position: Vector2) -> void:
    var center := global_position + size * 0.5
    direction = ((touch_position - center) / (minf(size.x, size.y) * 0.37)).limit_length(1.0)
    queue_redraw()

func _draw() -> void:
    var c := size * 0.5
    var r := minf(size.x, size.y) * 0.38
    draw_circle(c, r, Color(0.03, 0.18, 0.24, 0.36))
    draw_arc(c, r, 0.0, TAU, 48, Color(0.45, 0.84, 0.92, 0.52), 2.5)
    draw_circle(c + direction * r * 0.75, r * 0.35, Color(0.55, 0.95, 0.97, 0.7 if active else 0.46))
