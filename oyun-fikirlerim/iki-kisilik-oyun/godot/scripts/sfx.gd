extends Node
## Ses çalar: kısa efektler için oyuncu havuzu, rüzgâr ve uğultu döngüsü.

const NAMES := ["step", "jump", "land", "clink", "whoosh", "fire", "block", "door", "plate", "drag", "die", "win"]
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var muted := false

func _ready() -> void:
	for n: String in NAMES:
		_streams[n] = load("res://assets/audio/%s.wav" % n)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for n: String in ["wind", "drone"]:
		var s: AudioStreamWAV = load("res://assets/audio/%s.wav" % n)
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.volume_db = -14.0 if n == "wind" else -22.0
		add_child(p)
		if not Game.test_mode:
			p.play()

func play(n: String, vol_db: float = 0.0, pitch_var: float = 0.08) -> void:
	if muted or not _streams.has(n):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _streams[n]
			p.volume_db = vol_db
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
