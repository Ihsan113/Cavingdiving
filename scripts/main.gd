extends Node3D

const Sites = preload("res://scripts/dive_sites.gd")
const BoatScript = preload("res://scripts/boat_lobby.gd")
const CaveScript = preload("res://scripts/cave_builder.gd")
const DiverScript = preload("res://scripts/diver.gd")
const AudioScript = preload("res://scripts/dive_audio.gd")
const MapScript = preload("res://scripts/dive_map.gd")
const StickScript = preload("res://scripts/touch_joystick.gd")
const LookScript = preload("res://scripts/touch_look.gd")
const GlyphScript = preload("res://scripts/hud_glyph.gd")

const GAS_START: float = 300.0
const TURN_WARNING: float = 115.0
const GAS_CRITICAL: float = 40.0
const CYAN: Color = Color(0.49, 0.93, 0.93)
const WHITE: Color = Color(0.88, 0.96, 0.97)
const MUTED: Color = Color(0.60, 0.76, 0.79)
const GOLD: Color = Color(1.0, 0.73, 0.36)
const BG: Color = Color(0.019, 0.067, 0.085, 0.93)

enum Flow { TITLE, LOBBY, BRIEFING, DIVING, PAUSED, SUCCESS, FAILED }
var flow: Flow = Flow.TITLE
var site_index: int = 0
var boat: ExpeditionBoat
var cave: ProceduralCave
var diver: CaveDiver
var audio: CaveDiveAudio
var water_environment: WorldEnvironment
var boat_sound: AudioStreamPlayer
var sound_enabled: bool = true
var mobile: bool = false
var screen: Vector2 = Vector2(1280,720)

var gas_bar: float = GAS_START
var dive_seconds: float = 0.0
var max_depth_m: float = 0.0
var max_distance_m: float = 0.0
var objective_index: int = 0
var torch_on: bool = true
var ascend_held: bool = false
var descend_held: bool = false
var map_open: bool = false
var silt_clock: float = 0.0
var restriction_near: bool = false
var event_clock: float = 0.0
var hud_clock: float = 0.0

var ui: Control
var gas_label: Label
var depth_label: Label
var time_label: Label
var heading_label: Label
var objective_label: Label
var warning_label: Label
var event_label: Label
var gas_meter: ProgressBar
var smallmap: DiveMap
var bigmap: DiveMap
var map_overlay: Control
var joystick: DiveJoystick
var lookpad: DiveLookPad
var torch_button: Button
var audio_button: Button
var pause_overlay: Control

func _ready() -> void:
    Engine.max_fps = 60
    screen = get_viewport().get_visible_rect().size
    mobile = OS.has_feature("android") or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
    var layer := CanvasLayer.new()
    layer.name = "ExpeditionInterface"
    add_child(layer)
    ui = Control.new()
    ui.name = "FullScreenInterface"
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _open_boat_world()
    _show_title()

func _open_boat_world() -> void:
    if cave != null:
        remove_child(cave)
        cave.queue_free()
        cave = null
    if diver != null:
        remove_child(diver)
        diver.queue_free()
        diver = null
    if water_environment != null:
        remove_child(water_environment)
        water_environment.queue_free()
        water_environment = null
    if audio != null:
        audio.finish()
        audio.queue_free()
        audio = null
    if boat == null:
        boat = BoatScript.new()
        boat.name = "ExpeditionVesselLobby"
        add_child(boat)
    if boat_sound == null:
        boat_sound = AudioStreamPlayer.new()
        boat_sound.name = "OceanSurfaceAmbience"
        var file := load("res://assets/audio/boat_ocean.ogg") as AudioStreamOggVorbis
        if file != null:
            file.loop = true
            boat_sound.stream = file
        boat_sound.volume_db = -19
        add_child(boat_sound)
    if boat_sound.stream != null and sound_enabled and not boat_sound.playing:
        boat_sound.play()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _create_underwater_world() -> void:
    if boat_sound != null:
        boat_sound.stop()
    if boat != null:
        remove_child(boat)
        boat.queue_free()
        boat = null
    water_environment = WorldEnvironment.new()
    water_environment.name = "DeepWaterAtmosphere"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.004, 0.022, 0.034)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.12, 0.28, 0.32)
    env.ambient_light_energy = 0.24
    env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
    env.fog_enabled = true
    env.fog_light_color = Color(0.018,0.068,0.085)
    env.fog_density = 0.023 if site_index == 0 else 0.034
    water_environment.environment = env
    add_child(water_environment)
    cave = CaveScript.new()
    cave.name = Sites.title(site_index).replace(" ", "") + "Cavern"
    cave.site_index = site_index
    add_child(cave)
    diver = DiverScript.new()
    diver.name = "ExpeditionDiverPOV"
    diver.position = cave.route[0] + Vector3(0,0,1.4)
    diver.swim_speed = 5.2
    add_child(diver)
    audio = AudioScript.new()
    audio.name = "UnderwaterSoundscape"
    add_child(audio)
    audio.set_enabled(sound_enabled)
    gas_bar = GAS_START
    dive_seconds = 0
    max_depth_m = 0
    max_distance_m = 0
    objective_index = 0
    torch_on = true
    ascend_held = false
    descend_held = false
    map_open = false
    silt_clock = 0
    restriction_near = false
    event_clock = 0

func _clear_ui() -> void:
    for child in ui.get_children():
        child.queue_free()
    gas_label = null
    pause_overlay = null
    map_overlay = null

func _panel(parent: Node, pos: Vector2, extent: Vector2, opaque: float = 0.92, accent: bool = false) -> Panel:
    var panel := Panel.new()
    panel.position = pos
    panel.size = extent
    panel.custom_minimum_size = extent
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.017, 0.075, 0.097, opaque)
    style.border_color = Color(0.36,0.72,0.75,0.63) if accent else Color(0.18,0.38,0.42,0.66)
    style.set_border_width_all(1)
    style.set_corner_radius_all(15)
    style.shadow_color = Color(0,0,0,0.18)
    style.shadow_size = 5
    panel.add_theme_stylebox_override("panel",style)
    parent.add_child(panel)
    return panel

func _label(parent: Node, caption: String, pos: Vector2, extent: Vector2, px: int, tint: Color = WHITE, weight: bool = false) -> Label:
    var l := Label.new()
    l.position = pos
    l.size = extent
    l.text = caption
    l.clip_text = true
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",px)
    l.add_theme_color_override("font_color",tint)
    l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.46))
    l.add_theme_constant_override("shadow_offset_y",1)
    if weight:
        l.add_theme_constant_override("outline_size",1)
    parent.add_child(l)
    return l

func _button(parent: Node, label_text: String, glyph_name: String, pos: Vector2, extent: Vector2, action: Callable, primary: bool = false) -> Button:
    var b := Button.new()
    b.position = pos
    b.size = extent
    b.custom_minimum_size = extent
    b.focus_mode = Control.FOCUS_NONE
    b.clip_contents = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08,0.40,0.45,0.98) if primary else Color(0.046,0.16,0.19,0.97)
    style.border_color = CYAN if primary else Color(0.27,0.59,0.63,0.65)
    style.set_corner_radius_all(12)
    style.set_border_width_all(1)
    b.add_theme_stylebox_override("normal",style)
    var down: StyleBoxFlat = style.duplicate() as StyleBoxFlat
    down.bg_color = Color(0.13,0.51,0.55,1.0)
    b.add_theme_stylebox_override("pressed",down)
    b.add_theme_stylebox_override("hover",down)
    var icon := GlyphScript.new()
    icon.glyph = glyph_name
    var icon_dim := minf(extent.y - 9.0, 36.0)
    icon.position = Vector2(10,(extent.y - icon_dim)*0.5)
    icon.size = Vector2(icon_dim,icon_dim)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.add_child(icon)
    if label_text != "":
        var offset := icon_dim + 18.0
        var lab := _label(b,label_text,Vector2(offset,(extent.y - 24.0)*0.5),Vector2(extent.x - offset - 4,26),17 if extent.y>45 else 15,WHITE)
        lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _screen_veil(alpha: float = 0.45) -> ColorRect:
    var veil := ColorRect.new()
    veil.color = Color(0.003,0.022,0.032,alpha)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return veil

func _show_title() -> void:
    flow = Flow.TITLE
    _clear_ui()
    _screen_veil(0.39)
    var card := _panel(ui,Vector2(43,screen.y*0.18),Vector2(minf(500,screen.x*0.50),screen.y*0.66),0.88,true)
    _label(card,"EXPLORATION SERIES  /  VOL. 01",Vector2(26,26),Vector2(440,28),17,CYAN)
    _label(card,"CAVE",Vector2(24,68),Vector2(440,83),69,WHITE,true)
    _label(card,"DIVE",Vector2(24,137),Vector2(440,84),69,WHITE,true)
    _label(card,"BLUE ABYSS  •  EXPEDITION SIMULATOR",Vector2(28,238),Vector2(445,31),17,MUTED)
    _label(card,"A descent into the unseen. Two extended underwater cave systems, one way back to daylight.",Vector2(28,281),Vector2(card.size.x-52,70),18,WHITE)
    _button(card,"START EXPEDITION","play",Vector2(26,card.size.y-119),Vector2(card.size.x-52,55),_show_lobby,true)
    _button(ui,"AUDIO %s" % ("ON" if sound_enabled else "OFF"),"volume",Vector2(screen.x-216,23),Vector2(183,45),_toggle_menu_audio)
    _label(ui,"ANDROID EDITION  /  OFFLINE  /  VERSION 0.4",Vector2(screen.x-380,screen.y-34),Vector2(370,24),13,MUTED)

func _show_lobby() -> void:
    flow = Flow.LOBBY
    _clear_ui()
    _screen_veil(0.53)
    _label(ui,"EXPEDITION  /  SELECT DIVE SITE",Vector2(34,20),Vector2(screen.x-320,40),29,WHITE,true)
    _label(ui,"RESEARCH VESSEL  •  EQUIPMENT CHECK COMPLETE",Vector2(36,64),Vector2(750,25),15,CYAN)
    _button(ui,"AUDIO","volume",Vector2(screen.x-320,23),Vector2(132,45),_toggle_menu_audio)
    _button(ui,"MENU","back",Vector2(screen.x-172,23),Vector2(138,45),_show_title)
    var gap := 18.0
    var card_width := minf(430.0,(screen.x - 85.0)*0.47)
    for index in range(2):
        var x := 32.0 + float(index) * (card_width + gap)
        var card := _panel(ui,Vector2(x,116),Vector2(card_width,minf(488,screen.y-208)),0.93,site_index==index)
        var prefix := "01  /  SHALLOW SYSTEM" if index == 0 else "02  /  ADVANCED SYSTEM"
        _label(card,prefix,Vector2(18,14),Vector2(card_width-34,23),14,CYAN if index==site_index else MUTED)
        _label(card,Sites.title(index),Vector2(18,43),Vector2(card_width-34,38),26,WHITE,true)
        _label(card,Sites.location(index),Vector2(18,85),Vector2(card_width-34,25),12,MUTED)
        var preview := MapScript.new()
        preview.name = "RoutePreview%d" % index
        preview.route = Sites.route_for(index)
        preview.show_player = false
        preview.large = true
        preview.target_position = preview.route[preview.route.size()-1]
        preview.position = Vector2(16,121)
        preview.size = Vector2(card_width-32, minf(200,card.size.y*0.43))
        preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(preview)
        var stat_y := preview.position.y + preview.size.y + 14
        _label(card,"ROUTE  %d m" % Sites.distance_m(index),Vector2(18,stat_y),Vector2(card_width*0.5,24),18,GOLD)
        _label(card,"MAX  %d m" % Sites.depth_m(index),Vector2(card_width*0.52,stat_y),Vector2(card_width*0.43,24),18,WHITE)
        _label(card,"RESTRICTIONS: %s" % ("MODERATE" if index==0 else "HEAVY"),Vector2(18,stat_y+31),Vector2(card_width-40,22),15,MUTED)
        var choose_index := index
        _button(card,"SELECT SITE" if site_index!=index else "SELECTED","target",Vector2(16,card.size.y-64),Vector2(card_width-32,48),func(): _select_site(choose_index),site_index==index)
    var action_x := maxf(35.0,screen.x-325.0)
    var action_y := screen.y-151.0
    var briefing := _panel(ui,Vector2(action_x,action_y-83),Vector2(292,145),0.94,true)
    _label(briefing,"READY FOR BRIEFING",Vector2(18,13),Vector2(270,28),17,CYAN)
    _button(briefing,"CONTINUE","play",Vector2(17,63),Vector2(258,56),_show_briefing,true)

func _select_site(index: int) -> void:
    site_index = index
    _show_lobby()

func _toggle_menu_audio() -> void:
    sound_enabled = not sound_enabled
    if boat_sound != null:
        if sound_enabled:
            boat_sound.play()
        else:
            boat_sound.stop()
    match flow:
        Flow.TITLE: _show_title()
        Flow.LOBBY: _show_lobby()
        Flow.BRIEFING: _show_briefing()

func _toggle_dive_audio() -> void:
    sound_enabled = not sound_enabled
    if audio != null:
        audio.set_enabled(sound_enabled)
        audio.set_paused(true)
    if pause_overlay != null:
        pause_overlay.queue_free()
        pause_overlay = null
        _show_pause()

func _show_briefing() -> void:
    flow = Flow.BRIEFING
    _clear_ui()
    _screen_veil(0.72)
    var width := minf(670.0,screen.x-48)
    var height := minf(550.0,screen.y-44)
    var p := _panel(ui,Vector2((screen.x-width)*0.5,(screen.y-height)*0.5),Vector2(width,height),0.97,true)
    _label(p,"EXPEDITION BRIEFING  /  %02d" % (site_index+1),Vector2(24,23),Vector2(width-46,31),17,CYAN)
    _label(p,Sites.title(site_index),Vector2(22,64),Vector2(width-44,43),33,WHITE,true)
    _label(p,Sites.location(site_index),Vector2(23,113),Vector2(width-42,22),13,MUTED)
    _label(p,Sites.description(site_index),Vector2(24,151),Vector2(width-48,73),19,WHITE)
    var info := _panel(p,Vector2(24,232),Vector2(width-48,118),0.54)
    _label(info,"DISTANCE  %d m" % Sites.distance_m(site_index),Vector2(18,15),Vector2(260,30),19,GOLD)
    _label(info,"DEPTH  %d m" % Sites.depth_m(site_index),Vector2(width*0.53,15),Vector2(240,30),19,WHITE)
    _label(info,"CHECKPOINTS  03",Vector2(18,62),Vector2(270,27),17,WHITE)
    _label(info,"GAS  300 bar",Vector2(width*0.53,62),Vector2(250,27),17,WHITE)
    _label(p,"Follow the yellow guideline, record all three sites, then return to the entrance. This is a game; gauges are not for real dive planning.",Vector2(24,height-173),Vector2(width-48,61),15,MUTED)
    _button(p,"AUDIO","volume",Vector2(width-158,19),Vector2(132,44),_toggle_menu_audio)
    _button(p,"BACK","back",Vector2(23,height-75),Vector2(188,51),_show_lobby)
    _button(p,"BEGIN DESCENT","down",Vector2(width-275,height-75),Vector2(251,51),_begin_dive,true)

func _begin_dive() -> void:
    _create_underwater_world()
    flow = Flow.DIVING
    _build_dive_hud()
    diver.can_move = true
    audio.begin()
    if not mobile:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var black := ColorRect.new()
    black.color = Color(0.0,0.015,0.028,1.0)
    black.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(black)
    black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _label(black,"DESCENDING  /  %s" % Sites.title(site_index),Vector2(screen.x*0.35,screen.y*0.47),Vector2(screen.x*0.48,40),23,CYAN)
    var tween := create_tween()
    tween.tween_property(black,"modulate:a",0.0,1.9)
    tween.tween_callback(func(): black.queue_free())
    _update_hud()

func _build_dive_hud() -> void:
    _clear_ui()
    var telemetry := _panel(ui,Vector2(14,14),Vector2(318,166),0.86,true)
    _label(telemetry,"DIVE COMPUTER     /     DC-04",Vector2(16,11),Vector2(290,26),14,CYAN)
    gas_label = _label(telemetry,"300 BAR",Vector2(48,37),Vector2(232,42),31,WHITE,true)
    _add_icon(telemetry,"tank",Vector2(15,42),Vector2(31,31))
    gas_meter = ProgressBar.new()
    gas_meter.position = Vector2(17,82)
    gas_meter.size = Vector2(283,9)
    gas_meter.max_value = GAS_START
    gas_meter.value = GAS_START
    gas_meter.show_percentage = false
    var back_style := StyleBoxFlat.new()
    back_style.bg_color = Color(0.085,0.19,0.21)
    var fill_style := StyleBoxFlat.new()
    fill_style.bg_color = CYAN
    gas_meter.add_theme_stylebox_override("background",back_style)
    gas_meter.add_theme_stylebox_override("fill",fill_style)
    telemetry.add_child(gas_meter)
    _add_icon(telemetry,"depth",Vector2(15,109),Vector2(28,28))
    depth_label = _label(telemetry,"0.0 m",Vector2(46,107),Vector2(111,30),22,WHITE)
    _add_icon(telemetry,"clock",Vector2(163,108),Vector2(28,28))
    time_label = _label(telemetry,"00:00",Vector2(191,107),Vector2(114,30),21,WHITE)
    heading_label = _label(telemetry,"HDG 000°",Vector2(19,139),Vector2(275,23),15,MUTED)

    var mission_w := minf(390,screen.x*0.34)
    var mission := _panel(ui,Vector2(screen.x*0.5-mission_w*0.5,14),Vector2(mission_w,92),0.84)
    _label(mission,"MISSION / %s" % Sites.title(site_index),Vector2(13,12),Vector2(mission_w-26,24),14,CYAN)
    objective_label = _label(mission,"SITE 01  /  FOLLOW GUIDELINE",Vector2(14,43),Vector2(mission_w-23,40),19,GOLD)

    var map_w := 194.0
    var smallmap_frame := _panel(ui,Vector2(screen.x-map_w-17,13),Vector2(map_w,181),0.90)
    smallmap = MapScript.new()
    smallmap.name = "LocalCaveSurvey"
    smallmap.route = cave.route
    smallmap.checkpoints = cave.marker_positions
    smallmap.position = Vector2(5,5)
    smallmap.size = Vector2(map_w-10,171)
    smallmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    smallmap_frame.add_child(smallmap)

    var pause := _button(ui,"","pause",Vector2(screen.x-75,201),Vector2(59,54),_toggle_pause)
    pause.name = "PauseDiveButton"
    var map_btn := _button(ui,"","map",Vector2(screen.x-146,201),Vector2(59,54),_toggle_map)
    map_btn.name = "OpenMapButton"

    warning_label = _label(ui,"",Vector2(screen.x*0.31,112),Vector2(screen.x*0.42,39),17,Color(1.0,0.52,0.41))
    warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    event_label = _label(ui,"",Vector2(screen.x*0.27,150),Vector2(screen.x*0.48,40),21,CYAN)
    event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var joystick_size := 178.0
    joystick = StickScript.new()
    joystick.name = "MobileSwimStick"
    joystick.position = Vector2(26,screen.y-joystick_size-26)
    joystick.size = Vector2(joystick_size,joystick_size)
    joystick.visible = mobile
    ui.add_child(joystick)

    lookpad = LookScript.new()
    lookpad.name = "MobileAimDragArea"
    lookpad.position = Vector2(screen.x*0.33,screen.y*0.26)
    lookpad.size = Vector2(screen.x*0.44,screen.y*0.67)
    lookpad.visible = mobile
    ui.add_child(lookpad)

    torch_button = _button(ui,"","torch",Vector2(screen.x-94,screen.y-302),Vector2(70,65),_toggle_torch,true)
    torch_button.name = "TorchIconButton"
    var up := _button(ui,"","up",Vector2(screen.x-94,screen.y-222),Vector2(70,68),func(): pass)
    up.name = "AscendArrowButton"
    up.button_down.connect(func(): ascend_held = true)
    up.button_up.connect(func(): ascend_held = false)
    var down := _button(ui,"","down",Vector2(screen.x-94,screen.y-141),Vector2(70,68),func(): pass)
    down.name = "DescendArrowButton"
    down.button_down.connect(func(): descend_held = true)
    down.button_up.connect(func(): descend_held = false)
    _label(ui,"SWIM",Vector2(78,screen.y-32),Vector2(90,20),13,MUTED)
    _label(ui,"LOOK / DRAG",Vector2(screen.x*0.52,screen.y-32),Vector2(160,20),13,MUTED)

    map_overlay = Control.new()
    map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    map_overlay.visible = false
    ui.add_child(map_overlay)
    map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0.003,0.025,0.036,0.80)
    map_overlay.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var full_width := minf(screen.x*0.74,820.0)
    var full_height := minf(screen.y*0.84,590.0)
    var fullpanel := _panel(map_overlay,Vector2((screen.x-full_width)*0.5,(screen.y-full_height)*0.5),Vector2(full_width,full_height),0.97,true)
    bigmap = MapScript.new()
    bigmap.name = "ExpeditionSurveyMap"
    bigmap.large = true
    bigmap.route = cave.route
    bigmap.checkpoints = cave.marker_positions
    bigmap.position = Vector2(16,18)
    bigmap.size = Vector2(full_width-32,full_height-100)
    fullpanel.add_child(bigmap)
    _label(fullpanel,"%s   /   %d m ROUTE   /   MAX %d m" % [Sites.title(site_index),Sites.distance_m(site_index),Sites.depth_m(site_index)],Vector2(25,full_height-75),Vector2(full_width-185,38),16,MUTED)
    _button(fullpanel,"CLOSE","close",Vector2(full_width-154,full_height-74),Vector2(135,49),_toggle_map,true)

func _add_icon(parent: Node, kind: String, pos: Vector2, extent: Vector2) -> void:
    var g := GlyphScript.new()
    g.glyph = kind
    g.position = pos
    g.size = extent
    parent.add_child(g)

func _process(delta: float) -> void:
    if flow != Flow.DIVING:
        return
    if event_clock > 0.0:
        event_clock -= delta
        if event_clock <= 0.0:
            event_label.text = ""
    diver.input_move = Vector2.ZERO if map_open else Vector2(joystick.direction.x,-joystick.direction.y)
    diver.input_ascend = 0.0 if map_open else (1.0 if ascend_held else 0.0)
    diver.input_descend = 0.0 if map_open else (1.0 if descend_held else 0.0)
    if mobile and not map_open:
        diver.apply_look(lookpad.consume_delta() * 1.35)
    audio.set_swimming(diver.velocity.length())
    _simulate_dive(delta)
    hud_clock -= delta
    if flow == Flow.DIVING and hud_clock <= 0.0:
        _update_hud()
        hud_clock = 0.12

func _simulate_dive(delta: float) -> void:
    dive_seconds += delta
    var depth := maxf(0.0,-diver.global_position.y)
    max_depth_m = maxf(max_depth_m,depth)
    max_distance_m = maxf(max_distance_m,diver.position.distance_to(cave.route[0]))
    # Deliberately gameplay-scaled gas economy; NOT decompression / gas planning software.
    var effort := 1.40 if diver.boosted else 1.0
    gas_bar = maxf(0.0,gas_bar - (0.20 * (1.0+depth/12.0) * effort * delta))
    if gas_bar <= 0.0:
        _finish_dive(false,"BREATHING GAS DEPLETED")
        return
    if objective_index < cave.marker_positions.size():
        var goal := cave.marker_positions[objective_index]
        if diver.position.distance_to(goal) < 4.8:
            objective_index += 1
            audio.survey_complete()
            _toast("SITE %02d REGISTERED" % objective_index if objective_index < 3 else "SURVEY COMPLETE / RETURN TO ENTRY")
    elif diver.position.distance_to(cave.route[0]) < 5.6:
        _finish_dive(true,"ALL SITES RECORDED")
        return
    var nearest := cave.sample_path[0]
    var nearest_d := INF
    var nearest_index := 0
    for idx in range(cave.sample_path.size()):
        var path_point := cave.sample_path[idx]
        var d := path_point.distance_squared_to(diver.position)
        if d < nearest_d:
            nearest = path_point
            nearest_index = idx
            nearest_d = d
    var fraction := float(nearest_index) / float(maxi(1,cave.sample_path.size()-1))
    restriction_near = ((fraction > 0.38 and fraction < 0.45) or (fraction > 0.82 and fraction < 0.88)) if site_index == 0 else ((fraction > 0.17 and fraction < 0.23) or (fraction > 0.44 and fraction < 0.53) or (fraction > 0.77 and fraction < 0.84))
    if diver.position.y < nearest.y-1.25 and diver.velocity.length() > 3.7:
        silt_clock = 2.8
    else:
        silt_clock = maxf(0.0,silt_clock-delta)
    var base := 0.023 if site_index==0 else 0.034
    water_environment.environment.fog_density = lerpf(water_environment.environment.fog_density,base*2.4 if silt_clock>0 else base,delta*1.5)

func _target() -> Vector3:
    return cave.marker_positions[objective_index] if objective_index < cave.marker_positions.size() else cave.route[0]

func _update_hud() -> void:
    if gas_label == null or diver == null:
        return
    gas_label.text = "%03d BAR" % int(ceilf(gas_bar))
    gas_label.add_theme_color_override("font_color",Color(1.0,0.45,0.36) if gas_bar<GAS_CRITICAL else GOLD if gas_bar<TURN_WARNING else WHITE)
    gas_meter.value = gas_bar
    depth_label.text = "%.1f m" % maxf(0.0,-diver.position.y)
    time_label.text = "%02d:%02d" % [int(dive_seconds)/60,int(dive_seconds)%60]
    heading_label.text = "HDG %03d°  |  %s" % [posmod(-int(roundf(rad_to_deg(diver.rotation.y))),360),"TORCH ON" if torch_on else "TORCH OFF"]
    var distance := diver.position.distance_to(_target())
    objective_label.text = "SITE %02d/03  •  %d m" % [objective_index+1,int(distance)] if objective_index < 3 else "RETURN TO ENTRY  •  %d m" % int(distance)
    if gas_bar<GAS_CRITICAL:
        warning_label.text = "CRITICAL GAS  /  RETURN NOW"
    elif gas_bar<TURN_WARNING and objective_index<3:
        warning_label.text = "LOW GAS  /  CONSIDER RETURN"
    elif silt_clock > 0:
        warning_label.text = "SILT DISTURBED  /  LOW VISIBILITY"
    elif restriction_near:
        warning_label.text = "TIGHT PASSAGE  /  SLOW DOWN"
    else:
        warning_label.text = ""
    for map_node in [smallmap,bigmap]:
        map_node.diver_position = diver.position
        map_node.diver_yaw = diver.rotation.y
        map_node.target_position = _target()
        map_node.recorded_sites = objective_index
        if map_node == smallmap or map_open:
            map_node.queue_redraw()

func _toast(msg: String) -> void:
    if event_label != null:
        event_label.text = msg
        event_clock = 3.5

func _toggle_torch() -> void:
    if flow != Flow.DIVING:
        return
    torch_on = not torch_on
    diver.set_torch(torch_on)
    torch_button.modulate = Color(1,1,1) if torch_on else Color(0.5,0.6,0.65)

func _toggle_map() -> void:
    if flow != Flow.DIVING:
        return
    map_open = not map_open
    map_overlay.visible = map_open
    ascend_held = false
    descend_held = false
    diver.can_move = not map_open
    if lookpad != null:
        lookpad.pending_delta = Vector2.ZERO
        lookpad.touch_id = -1
    if map_open:
        bigmap.queue_redraw()

func _toggle_pause() -> void:
    if flow == Flow.DIVING:
        flow = Flow.PAUSED
        diver.can_move = false
        audio.set_paused(true)
        ascend_held = false
        descend_held = false
        if lookpad != null:
            lookpad.pending_delta = Vector2.ZERO
            lookpad.touch_id = -1
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _show_pause()
    elif flow == Flow.PAUSED:
        _resume()

func _show_pause() -> void:
    pause_overlay = Control.new()
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    ui.add_child(pause_overlay)
    pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade := ColorRect.new()
    shade.color = Color(0,0.025,0.037,0.78)
    pause_overlay.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var width := 450.0
    var p := _panel(pause_overlay,Vector2((screen.x-width)*0.5,(screen.y-344)*0.5),Vector2(width,344),0.98,true)
    _label(p,"EXPEDITION ON HOLD",Vector2(23,24),Vector2(340,36),28,WHITE,true)
    _button(p,"","volume",Vector2(376,22),Vector2(52,45),_toggle_dive_audio)
    _label(p,"Use the guideline to find your way back.",Vector2(24,76),Vector2(400,30),16,MUTED)
    _label(p,"SWIM  /  LEFT STICK     LOOK  /  DRAG\nASCEND + DESCEND  /  RIGHT ARROWS",Vector2(24,118),Vector2(408,64),15,CYAN)
    _button(p,"RESUME","play",Vector2(24,207),Vector2(401,52),_resume,true)
    _button(p,"RETURN TO BOAT","back",Vector2(24,272),Vector2(401,48),_return_to_boat)

func _resume() -> void:
    if pause_overlay != null:
        pause_overlay.queue_free()
        pause_overlay = null
    flow = Flow.DIVING
    diver.can_move = not map_open
    audio.set_paused(false)
    if lookpad != null:
        lookpad.pending_delta = Vector2.ZERO
        lookpad.touch_id = -1
    if not mobile:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _finish_dive(success: bool, message: String) -> void:
    flow = Flow.SUCCESS if success else Flow.FAILED
    diver.can_move = false
    audio.finish()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _clear_ui()
    _screen_veil(0.80)
    var width := 560.0
    var p := _panel(ui,Vector2((screen.x-width)*0.5,(screen.y-472)*0.5),Vector2(width,472),0.98,true)
    _label(p,"MISSION COMPLETE" if success else "EXPEDITION LOST",Vector2(25,28),Vector2(500,47),36,CYAN if success else Color(1,0.48,0.35),true)
    _label(p,message,Vector2(25,91),Vector2(510,38),20,WHITE)
    _label(p,"SITE  /  %s" % Sites.title(site_index),Vector2(25,151),Vector2(510,26),16,MUTED)
    _label(p,"DIVE TIME       %02d:%02d" % [int(dive_seconds)/60,int(dive_seconds)%60],Vector2(25,190),Vector2(500,30),20,WHITE)
    _label(p,"MAX DEPTH       %.1f m" % max_depth_m,Vector2(25,225),Vector2(500,30),20,WHITE)
    _label(p,"MAX RANGE       %.0f m" % max_distance_m,Vector2(25,260),Vector2(500,30),20,WHITE)
    _label(p,"REMAINING GAS   %d bar  /  SITES %d/3" % [int(gas_bar),objective_index],Vector2(25,295),Vector2(510,30),19,GOLD)
    _button(p,"DIVE AGAIN","play",Vector2(25,375),Vector2(245,57),_begin_dive,true)
    _button(p,"BACK TO BOAT","back",Vector2(289,375),Vector2(245,57),_return_to_boat)

func _return_to_boat() -> void:
    _open_boat_world()
    _show_lobby()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if not event.pressed or event.echo:
            return
        match event.physical_keycode:
            KEY_ESCAPE, KEY_P:
                if flow == Flow.DIVING or flow == Flow.PAUSED:
                    _toggle_pause()
            KEY_M:
                if flow == Flow.DIVING:
                    _toggle_map()
            KEY_F:
                if flow == Flow.DIVING:
                    _toggle_torch()

