extends CharacterBody3D
class_name CaveDiver

var swim_speed: float = 4.0
var boost_multiplier: float = 1.5
var yaw_sensitivity: float = 0.0024
var pitch_sensitivity: float = 0.0020
var input_move: Vector2 = Vector2.ZERO
var input_ascend: float = 0.0
var input_descend: float = 0.0
var can_move: bool = false
var boosted: bool = false

var camera: Camera3D
var lamp: SpotLight3D

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.39
    capsule.height = 1.35
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    add_child(collider)

    camera = Camera3D.new()
    camera.name = "DiverPOVCamera"
    camera.fov = 79.0
    camera.current = true
    add_child(camera)

    lamp = SpotLight3D.new()
    lamp.name = "PrimaryDiveTorch"
    lamp.position = Vector3(0.22, -0.18, -0.12)
    lamp.rotation_degrees.x = -3.0
    lamp.light_color = Color(0.77, 0.92, 1.0)
    lamp.light_energy = 3.5
    lamp.spot_range = 27.0
    lamp.spot_angle = 29.0
    lamp.shadow_enabled = false
    camera.add_child(lamp)

func _unhandled_input(event: InputEvent) -> void:
    if not can_move:
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        apply_look(event.relative)

func apply_look(relative: Vector2) -> void:
    if not can_move:
        return
    rotate_y(-relative.x * yaw_sensitivity)
    camera.rotation.x = clampf(camera.rotation.x - relative.y * pitch_sensitivity, -1.45, 1.45)

func _physics_process(delta: float) -> void:
    if not can_move:
        velocity = Vector3.ZERO
        return
    var move_x := input_move.x
    var move_z := input_move.y
    if Input.is_physical_key_pressed(KEY_A): move_x -= 1.0
    if Input.is_physical_key_pressed(KEY_D): move_x += 1.0
    if Input.is_physical_key_pressed(KEY_W): move_z += 1.0
    if Input.is_physical_key_pressed(KEY_S): move_z -= 1.0
    var vertical := input_ascend - input_descend
    if Input.is_physical_key_pressed(KEY_SPACE): vertical += 1.0
    if Input.is_physical_key_pressed(KEY_CTRL): vertical -= 1.0

    boosted = Input.is_physical_key_pressed(KEY_SHIFT)
    var heading := -global_transform.basis.z
    var right := global_transform.basis.x
    var aim := right * move_x + heading * move_z + Vector3.UP * vertical
    if aim.length_squared() > 1.0:
        aim = aim.normalized()
    var target := aim * swim_speed * (boost_multiplier if boosted else 1.0)
    velocity = velocity.move_toward(target, delta * 9.0)
    move_and_slide()

func set_torch(on: bool) -> void:
    lamp.visible = on
