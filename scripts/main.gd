extends Node3D

const DiverScript = preload("res://scripts/diver.gd")
const CaveScript = preload("res://scripts/cave_builder.gd")
const MapScript = preload("res://scripts/dive_map.gd")
const StickScript = preload("res://scripts/touch_joystick.gd")
const LookScript = preload("res://scripts/touch_look.gd")

const GAS_START: float = 220.0
const TURN_PRESSURE: float = 145.0
const CRITICAL_PRESSURE: float = 50.0

enum DiveState { INTRO, ACTIVE, PAUSED, SUCCESS, FAILED }

var state: DiveState = DiveState.INTRO
var cave: ProceduralCave
var diver: CaveDiver
var world_environment: WorldEnvironment
var gas_bar: float = GAS_START
var dive_seconds: float = 0.0
var deepest_m: float = 0.0
var max_distance_m: float = 0.0
var objective_index: int = 0
var torch_on: bool = true
var silt_time: float = 0.0
var ascend_held: bool = false
var descend_held: bool = false
var map_open: bool = false
var mobile: bool = false

var ui: Control
var gas_label: Label
var gas_meter: ProgressBar
var event_label: Label
var event_time: float = 0.0
var depth_label: Label
var time_label: Label
var heading_label: Label
var objective_label: Label
var warning_label: Label
var minimap: DiveMap
var map_panel: PanelContainer
var fullmap: DiveMap
var map_contents: Control
var joystick: DiveJoystick
var lookpad: DiveLookPad
var overlay: Control
var lamp_button: Button

func _ready() -> void:
    Engine.max_fps = 60
    mobile = OS.has_feature("android") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
    _create_environment()
    cave = CaveScript.new()
    cave.name = "FloodedLimestoneNetwork"
    add_child(cave)
    diver = DiverScript.new()
    diver.name = "PlayerDiver"
    diver.position = cave.route[0] + Vector3(0, 0, -1.0)
    add_child(diver)
    _build_interface()
    _update_hud()
    _show_dialog("CAVEDIVE: BLUE ABYSS", "MISSION 01 - CAVE SURVEY\n\nFollow the yellow rope to three glowing survey points. Return to the cave entrance before your breathing gas runs out.\n\nThis is a fictional exploration game, not real-world dive-planning software.", "BEGIN DIVE", _begin_dive)

func _create_environment() -> void:
    world_environment = WorldEnvironment.new()
    world_environment.name = "DarkUnderwaterEnvironment"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.005, 0.025, 0.047)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.19, 0.39, 0.48)
    env.ambient_light_energy = 0.33
    env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
    env.fog_enabled = true
    env.fog_light_color = Color(0.025, 0.10, 0.15)
    env.fog_density = 0.018
    world_environment.environment = env
    add_child(world_environment)

func _make_panel(parent: Control, where: Vector2, dims: Vector2) -> PanelContainer:
    var p := PanelContainer.new()
    p.position = where
    p.custom_minimum_size = dims
    p.size = dims
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.09, 0.12, 0.87)
    style.border_color = Color(0.26, 0.58, 0.65, 0.6)
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    style.content_margin_left = 15
    style.content_margin_right = 15
    style.content_margin_top = 11
    style.content_margin_bottom = 11
    p.add_theme_stylebox_override("panel", style)
    parent.add_child(p)
    return p

func _new_label(parent: Node, content: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    parent.add_child(label)
    return label

func _make_button(parent: Node, content: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = content
    b.custom_minimum_size = Vector2(116, 46)
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color(0.89, 0.98, 1.0))
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.055, 0.29, 0.35, 0.90)
    sb.border_color = Color(0.32, 0.70, 0.78, 0.88)
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(10)
    b.add_theme_stylebox_override("normal", sb)
    var sb_pressed := sb.duplicate()
    sb_pressed.bg_color = Color(0.16, 0.52, 0.61, 1)
    b.add_theme_stylebox_override("pressed", sb_pressed)
    b.add_theme_stylebox_override("hover", sb_pressed)
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _build_interface() -> void:
    var layer := CanvasLayer.new()
    layer.name = "DiverHelmetHUD"
    add_child(layer)
    ui = Control.new()
    layer.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var screen := get_viewport().get_visible_rect().size

    var stats := _make_panel(ui, Vector2(18, 18), Vector2(240, 187))
    var stats_col := VBoxContainer.new()
    stats_col.add_theme_constant_override("separation", 4)
    stats.add_child(stats_col)
    _new_label(stats_col, "DIVER TELEMETRY", 15, Color(0.44, 0.91, 0.94))
    gas_label = _new_label(stats_col, "GAS  220 bar", 24, Color(0.92, 0.99, 0.98))
    gas_meter = ProgressBar.new()
    gas_meter.min_value = 0.0
    gas_meter.max_value = GAS_START
    gas_meter.value = GAS_START
    gas_meter.show_percentage = false
    gas_meter.custom_minimum_size = Vector2(195, 11)
    var meter_bg := StyleBoxFlat.new()
    meter_bg.bg_color = Color(0.05, 0.14, 0.17)
    meter_bg.set_corner_radius_all(4)
    gas_meter.add_theme_stylebox_override("background", meter_bg)
    var meter_fg := StyleBoxFlat.new()
    meter_fg.bg_color = Color(0.36, 0.92, 0.85)
    meter_fg.set_corner_radius_all(4)
    gas_meter.add_theme_stylebox_override("fill", meter_fg)
    stats_col.add_child(gas_meter)
    depth_label = _new_label(stats_col, "DEPTH  0.0 m", 19, Color(0.8, 0.91, 0.96))
    time_label = _new_label(stats_col, "TIME   00:00", 18, Color(0.8, 0.91, 0.96))
    heading_label = _new_label(stats_col, "HDG    000 deg", 17, Color(0.8, 0.91, 0.96))

    minimap = MapScript.new()
    minimap.name = "TacticalMiniMap"
    minimap.position = Vector2(screen.x - 213.0, 18)
    minimap.size = Vector2(193, 200)
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    minimap.route = cave.route
    ui.add_child(minimap)

    var mission := _make_panel(ui, Vector2(screen.x * 0.5 - 241.0, 18), Vector2(482, 66))
    var mission_col := VBoxContainer.new()
    mission.add_child(mission_col)
    _new_label(mission_col, "MISSION / ROUTE STATUS", 13, Color(0.48, 0.89, 0.92))
    objective_label = _new_label(mission_col, "Follow guideline to survey site 01", 17, Color(1, 0.93, 0.76))

    warning_label = _new_label(ui, "", 22, Color(1.0, 0.40, 0.29))
    warning_label.position = Vector2(screen.x * 0.5 - 230.0, 99.0)
    warning_label.custom_minimum_size = Vector2(460, 36)
    warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    event_label = _new_label(ui, "", 22, Color(0.56, 1.0, 0.82))
    event_label.position = Vector2(screen.x * 0.5 - 260, 144)
    event_label.custom_minimum_size = Vector2(520, 36)
    event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var menu_row := HBoxContainer.new()
    menu_row.position = Vector2(screen.x - 284, 228)
    menu_row.add_theme_constant_override("separation", 6)
    ui.add_child(menu_row)
    var map_b := _make_button(menu_row, "MAP (M)", _toggle_map)
    map_b.custom_minimum_size = Vector2(127, 42)
    var pause_b := _make_button(menu_row, "PAUSE", _toggle_pause)
    pause_b.custom_minimum_size = Vector2(127, 42)

    var action_row := HBoxContainer.new()
    action_row.position = Vector2(screen.x - 281.0, screen.y - 80.0)
    action_row.add_theme_constant_override("separation", 8)
    ui.add_child(action_row)
    lamp_button = _make_button(action_row, "TORCH: ON", _toggle_torch)
    lamp_button.custom_minimum_size = Vector2(125, 52)
    var help_button := _make_button(action_row, "HELP", _show_help)
    help_button.custom_minimum_size = Vector2(125, 52)

    map_panel = _make_panel(ui, Vector2(screen.x * 0.5 - 254.0, screen.y * 0.5 - 224.0), Vector2(508, 448))
    map_panel.visible = false
    map_contents = Control.new()
    map_contents.custom_minimum_size = Vector2(478, 420)
    map_panel.add_child(map_contents)
    fullmap = MapScript.new()
    fullmap.name = "SurveyNavigationMap"
    fullmap.large = true
    fullmap.route = cave.route
    fullmap.custom_minimum_size = Vector2(478, 420)
    fullmap.size = Vector2(478, 420)
    fullmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_contents.add_child(fullmap)
    var close_map := _make_button(map_contents, "CLOSE MAP", _toggle_map)
    close_map.position = Vector2(338, 4)
    close_map.custom_minimum_size = Vector2(135, 40)

    joystick = StickScript.new()
    joystick.name = "SwimVirtualJoystick"
    joystick.size = Vector2(172, 172)
    joystick.position = Vector2(26, screen.y - 198)
    joystick.visible = mobile
    ui.add_child(joystick)

    lookpad = LookScript.new()
    lookpad.name = "TouchLookArea"
    lookpad.position = Vector2(screen.x * 0.50, screen.y * 0.28)
    lookpad.size = Vector2(screen.x * 0.47, screen.y * 0.48)
    lookpad.visible = mobile
    ui.add_child(lookpad)

    var vertical_controls := VBoxContainer.new()
    vertical_controls.name = "VerticalSwimControls"
    vertical_controls.position = Vector2(screen.x - 420, screen.y - 191)
    vertical_controls.add_theme_constant_override("separation", 10)
    vertical_controls.visible = mobile
    ui.add_child(vertical_controls)
    var ascend := _make_button(vertical_controls, "ASCEND", func(): pass)
    ascend.button_down.connect(func(): ascend_held = true)
    ascend.button_up.connect(func(): ascend_held = false)
    var descend := _make_button(vertical_controls, "DESCEND", func(): pass)
    descend.button_down.connect(func(): descend_held = true)
    descend.button_up.connect(func(): descend_held = false)

func _process(delta: float) -> void:
    if event_time > 0.0:
        event_time = maxf(0.0, event_time - delta)
        if event_time == 0.0:
            event_label.text = ""
    if state == DiveState.ACTIVE:
        diver.input_move = Vector2.ZERO if map_open else Vector2(joystick.direction.x, -joystick.direction.y)
        diver.input_ascend = 1.0 if ascend_held else 0.0
        diver.input_descend = 1.0 if descend_held else 0.0
        if mobile and not map_open:
            diver.apply_look(lookpad.consume_delta() * 1.4)
        _advance_dive(delta)
    if state == DiveState.ACTIVE or state == DiveState.PAUSED:
        _update_hud()

func _advance_dive(delta: float) -> void:
    dive_seconds += delta
    var depth := maxf(0.0, -diver.global_position.y)
    deepest_m = maxf(deepest_m, depth)
    max_distance_m = maxf(max_distance_m, diver.global_position.distance_to(cave.route[0]))

    # Game-scaled gas usage. Depth multiplier reflects ambient pressure.
    var activity := 1.45 if diver.boosted else 1.0
    var gas_used := 0.56 * (1.0 + depth / 10.0) * activity * delta
    gas_bar = maxf(0.0, gas_bar - gas_used)
    if gas_bar <= 0.0:
        _finish(false, "OUT OF BREATHING GAS")
        return

    if objective_index < cave.marker_positions.size():
        var goal := cave.marker_positions[objective_index]
        if diver.position.distance_to(goal) < 3.0:
            objective_index += 1
            if objective_index == cave.marker_positions.size():
                _flash_message("ALL SITES COMPLETE - RETURN TO ENTRANCE")
            else:
                _flash_message("SURVEY SITE %02d RECORDED" % objective_index)
    elif diver.position.distance_to(cave.route[0]) < 3.8:
        _finish(true, "ALL SURVEY SITES RECORDED")
        return

    var near := _closest_path_point(diver.position)
    if diver.position.y < near.y - 1.45 and diver.velocity.length() > 3.5:
        silt_time = 3.0
    else:
        silt_time = maxf(0.0, silt_time - delta)
    world_environment.environment.fog_density = lerpf(world_environment.environment.fog_density, 0.052 if silt_time > 0.0 else 0.018, delta * 1.9)

func _closest_path_point(p: Vector3) -> Vector3:
    var nearest := cave.sample_path[0]
    var distance_sq := INF
    for point in cave.sample_path:
        var d := p.distance_squared_to(point)
        if d < distance_sq:
            distance_sq = d
            nearest = point
    return nearest

func _current_target() -> Vector3:
    if objective_index < cave.marker_positions.size():
        return cave.marker_positions[objective_index]
    return cave.route[0]

func _update_hud() -> void:
    if gas_label == null:
        return
    gas_label.text = "GAS  %03d bar" % int(ceilf(gas_bar))
    gas_meter.value = gas_bar
    gas_label.add_theme_color_override("font_color", Color(1.0, 0.47, 0.36) if gas_bar <= CRITICAL_PRESSURE else Color(1.0, 0.82, 0.43) if gas_bar <= TURN_PRESSURE else Color(0.84, 1.0, 0.95))
    depth_label.text = "DEPTH  %.1f m" % maxf(0.0, -diver.position.y)
    time_label.text = "TIME   %02d:%02d" % [int(dive_seconds) / 60, int(dive_seconds) % 60]
    var bearing := posmod(-int(roundf(rad_to_deg(diver.rotation.y))), 360)
    heading_label.text = "HDG    %03d deg" % bearing
    var target := _current_target()
    var distance := diver.position.distance_to(target)
    if objective_index < cave.marker_positions.size():
        objective_label.text = "SITE %02d / 03  |  %.0f m to beacon" % [objective_index + 1, distance]
    else:
        objective_label.text = "RETURN TO ENTRANCE  |  %.0f m" % distance
    var alert := ""
    if gas_bar <= CRITICAL_PRESSURE:
        alert = "CRITICAL GAS - RETURN IMMEDIATELY"
    elif gas_bar <= TURN_PRESSURE and objective_index < cave.marker_positions.size():
        alert = "TURN PRESSURE REACHED - CONSIDER EXIT"
    elif silt_time > 0.0:
        alert = "SILT CLOUD - VISIBILITY REDUCED"
    elif -diver.position.y > 25.0:
        alert = "DEEP WATER - HIGHER GAS CONSUMPTION"
    elif not torch_on:
        alert = "PRIMARY TORCH OFF"
    warning_label.text = alert
    minimap.diver_position = diver.position
    minimap.diver_yaw = diver.rotation.y
    minimap.target_position = target
    minimap.queue_redraw()
    fullmap.diver_position = diver.position
    fullmap.diver_yaw = diver.rotation.y
    fullmap.target_position = target
    if map_open:
        fullmap.queue_redraw()

func _flash_message(content: String) -> void:
    event_label.text = content
    event_time = 4.5

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_M:
                if state == DiveState.ACTIVE or state == DiveState.PAUSED:
                    _toggle_map()
            KEY_F:
                if state == DiveState.ACTIVE:
                    _toggle_torch()
            KEY_ESCAPE, KEY_P:
                if state == DiveState.ACTIVE or state == DiveState.PAUSED:
                    _toggle_pause()

func _begin_dive() -> void:
    _hide_dialog()
    state = DiveState.ACTIVE
    diver.can_move = true
    if not mobile:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_torch() -> void:
    if state != DiveState.ACTIVE:
        return
    torch_on = not torch_on
    diver.set_torch(torch_on)
    lamp_button.text = "TORCH: ON" if torch_on else "TORCH: OFF"

func _toggle_map() -> void:
    map_open = not map_open
    map_panel.visible = map_open
    if map_open:
        ascend_held = false
        descend_held = false
    diver.can_move = (state == DiveState.ACTIVE and not map_open)
    if map_open:
        fullmap.queue_redraw()

func _toggle_pause() -> void:
    if state == DiveState.ACTIVE:
        state = DiveState.PAUSED
        diver.can_move = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _show_dialog("DIVE PAUSED", "MISSION: Survey the three beacons and return.\n\nWASD: swim  |  Mouse: look\nSpace / Ctrl: ascend / descend\nShift: faster swim (uses more gas)\nF: torch  |  M: map  |  ESC: pause", "RESUME", _resume_dive)
    elif state == DiveState.PAUSED:
        _resume_dive()

func _resume_dive() -> void:
    _hide_dialog()
    state = DiveState.ACTIVE
    diver.can_move = true
    if not mobile:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _show_help() -> void:
    if state == DiveState.ACTIVE:
        _toggle_pause()

func _finish(success: bool, result: String) -> void:
    state = DiveState.SUCCESS if success else DiveState.FAILED
    diver.can_move = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var summary := "%s\n\nDive time: %02d:%02d\nMax depth: %.1f m\nFarthest distance: %.0f m\nRemaining gas: %d bar\nSurvey sites: %d / 3" % [
        result, int(dive_seconds) / 60, int(dive_seconds) % 60,
        deepest_m, max_distance_m, int(gas_bar), objective_index
    ]
    _show_dialog("MISSION COMPLETE" if success else "DIVE FAILED", summary, "RESTART", _restart)

func _restart() -> void:
    get_tree().reload_current_scene()

func _show_dialog(header: String, description: String, button_text: String, action: Callable) -> void:
    _hide_dialog()
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    ui.add_child(overlay)
    var scr := get_viewport().get_visible_rect().size
    var veil := ColorRect.new()
    veil.color = Color(0.006, 0.035, 0.059, 0.86)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(veil)
    var width := minf(575.0, scr.x - 35.0)
    var height := minf(385.0, scr.y - 20.0)
    var popup := _make_panel(overlay, Vector2((scr.x - width) * 0.5, (scr.y - height) * 0.5), Vector2(width, height))
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 17)
    popup.add_child(stack)
    _new_label(stack, header, 28, Color(0.48, 0.95, 0.98))
    var desc := _new_label(stack, description, 18, Color(0.85, 0.93, 0.97))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var start := _make_button(stack, button_text, action)
    start.custom_minimum_size = Vector2(170, 50)

func _hide_dialog() -> void:
    if overlay != null:
        overlay.queue_free()
        overlay = null
