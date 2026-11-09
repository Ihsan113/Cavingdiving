extends Control
class_name DiveLookPad

var touch_id: int = -1
var pending_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not visible:
        touch_id = -1
        pending_delta = Vector2.ZERO
        return
    if event is InputEventScreenTouch:
        if event.pressed and touch_id == -1 and get_global_rect().has_point(event.position):
            touch_id = event.index
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
    elif event is InputEventScreenDrag and event.index == touch_id:
        pending_delta += event.relative

func consume_delta() -> Vector2:
    var result := pending_delta
    pending_delta = Vector2.ZERO
    return result
