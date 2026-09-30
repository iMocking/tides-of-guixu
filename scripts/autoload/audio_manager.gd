extends Node
## Procedural audio manager. It synthesizes short UI/gameplay tones without external assets.

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _phase := 0.0
var _mix_rate := 22050.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = _mix_rate
    generator.buffer_length = 0.25
    _player = AudioStreamPlayer.new()
    _player.stream = generator
    add_child(_player)
    _player.play()
    var pb := _player.get_stream_playback()
    if pb is AudioStreamGeneratorPlayback:
        _playback = pb

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

func _process(_delta: float) -> void:
    if _playback == null:
        return
    if _current.is_empty() and not _queue.is_empty():
        _current = _queue.pop_front()
        _current["elapsed"] = 0.0
        _phase = 0.0
    if _current.is_empty():
        return
    var frames := _playback.get_frames_available()
    if frames <= 0:
        return
    var frequency := float(_current["frequency"])
    var duration := float(_current["duration"])
    var volume := float(_current["volume"])
    var elapsed := float(_current.get("elapsed", 0.0))
    for i in range(frames):
        if elapsed >= duration:
            _current = {}
            _playback.push_frame(Vector2.ZERO)
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
        _playback.push_frame(Vector2(sample, sample))
        elapsed += 1.0 / _mix_rate
    if not _current.is_empty():
        _current["elapsed"] = elapsed