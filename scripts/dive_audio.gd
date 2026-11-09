extends Node
class_name CaveDiveAudio

# All audio is original, generated locally, and bundled as compact .ogg assets.
var enabled: bool = true
var active: bool = false
var swim_velocity: float = 0.0
var bubbles_clock: float = 3.7
var fins_clock: float = 0.8

var ambience: AudioStreamPlayer
var breath: AudioStreamPlayer
var bubbles: AudioStreamPlayer
var fins: AudioStreamPlayer
var ping: AudioStreamPlayer
var impact: AudioStreamPlayer
var radio: AudioStreamPlayer

func _ready() -> void:
    ambience = _make_sound("CaveWaterDrone", "underwater_ambience.ogg", -20.0, true)
    breath = _make_sound("RegulatorBreathing", "regulator_breath.ogg", -10.0, true)
    bubbles = _make_sound("ExhaledAirBubbles", "bubbles_release.ogg", -14.0, false)
    fins = _make_sound("FinSwimSound", "fin_swoosh.ogg", -23.0, false)
    ping = _make_sound("SurveyBeaconSignal", "survey_ping.ogg", -13.0, false)
    impact = _make_sound("SharpRockImpact", "rock_contact.ogg", -7.0, false)
    radio = _make_sound("InstructorCommsChirp", "radio_chirp.ogg", -15.0, false)
    set_process(true)

func _make_sound(node_name: String, file: String, db: float, looping: bool) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.name = node_name
    var clip := load("res://assets/audio/" + file) as AudioStreamOggVorbis
    if clip != null:
        clip.loop = looping
        player.stream = clip
    player.volume_db = db
    add_child(player)
    return player

func begin() -> void:
    active = true
    bubbles_clock = 3.75
    fins_clock = 0.7
    if enabled:
        ambience.play()
        breath.play()

func finish() -> void:
    active = false
    for player in [ambience, breath, bubbles, fins, ping, impact, radio]:
        player.stop()

func set_paused(paused: bool) -> void:
    for player in [ambience, breath, bubbles, fins, ping, impact, radio]:
        player.stream_paused = paused

func set_enabled(value: bool) -> void:
    if enabled == value:
        return
    enabled = value
    if not enabled:
        for player in [ambience, breath, bubbles, fins, ping, impact, radio]:
            player.stop()
    elif active:
        ambience.play()
        breath.play()

func rock_contact() -> void:
    if active and enabled:
        impact.play()

func radio_message() -> void:
    if active and enabled:
        radio.play()

func survey_complete() -> void:
    if active and enabled:
        ping.play()

func set_swimming(speed: float) -> void:
    swim_velocity = speed

func _process(delta: float) -> void:
    if not active or not enabled or ambience.stream_paused:
        return
    bubbles_clock -= delta
    fins_clock -= delta
    if bubbles_clock <= 0.0:
        bubbles.pitch_scale = randf_range(0.94, 1.08)
        bubbles.play()
        bubbles_clock = 6.0
    if swim_velocity > 1.4 and fins_clock <= 0.0:
        fins.pitch_scale = randf_range(0.92, 1.08)
        fins.play()
        fins_clock = 1.65 if swim_velocity < 4.7 else 1.1
