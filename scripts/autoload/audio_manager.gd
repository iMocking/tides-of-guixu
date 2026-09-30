extends Node
## Procedural audio manager. It synthesizes short UI/gameplay tones without external assets.

var _sfx_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback
var _music_player: AudioStreamPlayer
var _music_playback: AudioStreamGeneratorPlayback
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _phase := 0.0
var _mix_rate := 22050.0

## Slow pentatonic ambient notes, one at a time, for the background music bus.
const MUSIC_NOTES := [220.0, 246.94, 293.66, 329.63, 392.0, 440.0]
var _music_rng := RandomNumberGenerator.new()
var _music_phase := 0.0
var _music_note := 0.0
var _music_elapsed := 0.0
var _music_duration := 3.0
var _music_amp := 0.0
var _music_timer := 2.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _music_rng.randomize()
    _ensure_buses()
    _sfx_player = _make_generator_player("SFX")
    _music_player = _make_generator_player("Music")
    var sfx := _sfx_player.get_stream_playback()
    if sfx is AudioStreamGeneratorPlayback:
        _sfx_playback = sfx
    var music := _music_player.get_stream_playback()
    if music is AudioStreamGeneratorPlayback:
        _music_playback = music
    GameState.apply_audio_settings()


## Creates the SFX / Music buses (routed to Master) once.
func _ensure_buses() -> void:
    for bus_name in ["SFX", "Music"]:
        if AudioServer.get_bus_index(bus_name) >= 0:
            continue
        AudioServer.add_bus()
        var index := AudioServer.bus_count - 1
        AudioServer.set_bus_name(index, bus_name)
        AudioServer.set_bus_send(index, "Master")


func _make_generator_player(bus_name: String) -> AudioStreamPlayer:
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = _mix_rate
    generator.buffer_length = 0.25
    var player := AudioStreamPlayer.new()
    player.stream = generator
    player.bus = bus_name
    add_child(player)
    player.play()
    return player

func play_ui_click() -> void:
    _queue_tone(660.0, 0.05, 0.08)

func play_ui_confirm() -> void:
    _queue_tone(880.0, 0.08, 0.09)

func play_hit() -> void:
    _queue_tone(180.0, 0.10, 0.11)

func play_pickup() -> void:
    _queue_tone(980.0, 0.09, 0.08)

func play_level_up() -> void:
    _queue_tone(523.25, 0.12, 0.12)
    _queue_tone(783.99, 0.18, 0.10)

func play_achievement() -> void:
    _queue_tone(659.25, 0.10, 0.10)
    _queue_tone(987.77, 0.22, 0.11)

func _queue_tone(frequency: float, duration: float, volume: float) -> void:
    _queue.append({"frequency": frequency, "duration": duration, "volume": volume})

func _process(delta: float) -> void:
    _advance_music(delta)
    if _sfx_playback != null:
        _fill_sfx(_sfx_playback.get_frames_available())
    if _music_playback != null:
        _fill_music(_music_playback.get_frames_available())


## Starts a new ambient note when the previous one has rung out.
func _advance_music(delta: float) -> void:
    _music_timer -= delta
    if _music_timer > 0.0:
        return
    if _music_amp > 0.0 and _music_elapsed < _music_duration:
        return
    _music_timer = _music_rng.randf_range(1.4, 3.2)
    _music_note = MUSIC_NOTES[_music_rng.randi() % MUSIC_NOTES.size()]
    _music_phase = 0.0
    _music_elapsed = 0.0
    _music_duration = _music_rng.randf_range(2.4, 3.8)
    _music_amp = 0.18


func _fill_music(frames: int) -> void:
    if frames <= 0:
        return
    for _i in range(frames):
        var sample := 0.0
        if _music_amp > 0.0001 and _music_elapsed < _music_duration:
            var envelope := 1.0
            if _music_elapsed < 0.4:
                envelope = _music_elapsed / 0.4
            var remain := _music_duration - _music_elapsed
            if remain < 1.1:
                envelope = minf(envelope, remain / 1.1)
            var wave := sin(_music_phase) * 0.72 + sin(_music_phase * 2.0) * 0.20 + sin(_music_phase * 3.02) * 0.07
            sample = wave * _music_amp * envelope
            _music_phase = fmod(_music_phase + TAU * _music_note / _mix_rate, TAU)
            _music_elapsed += 1.0 / _mix_rate
        _music_playback.push_frame(Vector2(sample, sample))


func _fill_sfx(frames: int) -> void:
    if frames <= 0:
        return
    if _current.is_empty() and not _queue.is_empty():
        _current = _queue.pop_front()
        _current["elapsed"] = 0.0
        _phase = 0.0
    if _current.is_empty():
        return
    var frequency := float(_current["frequency"])
    var duration := float(_current["duration"])
    var volume := float(_current["volume"])
    var elapsed := float(_current.get("elapsed", 0.0))
    for i in range(frames):
        if elapsed >= duration:
            _current = {}
            _sfx_playback.push_frame(Vector2.ZERO)
            continue
        var attack := 0.03
        var envelope := 1.0
        if elapsed < attack:
            envelope = elapsed / attack
        var remain := duration - elapsed
        if remain < attack:
            envelope = maxf(remain / attack, 0.0)
        var sample := sin(_phase) * volume * envelope
        _phase = fmod(_phase + TAU * frequency / _mix_rate, TAU)
        _sfx_playback.push_frame(Vector2(sample, sample))
        elapsed += 1.0 / _mix_rate
    if not _current.is_empty():
        _current["elapsed"] = elapsed