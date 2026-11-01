class_name ProtoAudio extends Node
## Prototip bölümün sesleri: tek seferlik efektler (rastgele çeşit + perde), ambiyans ve Sisli uğultusu döngüleri,
## tehlikeye göre hızlanan kalp atışı, final müziği.

var streams := {}           # ad -> [AudioStream, ...] (çeşitler)
var pool: Array[AudioStreamPlayer] = []
var amb: AudioStreamPlayer
var drone: AudioStreamPlayer
var music: AudioStreamPlayer
var danger := 0.0           # 0..1: Sisli yakınlığı
var _beat_t := 0.0
var muted := false

func _ready() -> void:
	var d := DirAccess.open("res://proto/ses")
	var names := []
	if d != null:
		for f in d.get_files():
			var fn := f.trim_suffix(".import")
			if fn.ends_with(".wav") and not names.has(fn):
				names.append(fn)
	for f: String in names:
		var base := f.trim_suffix(".wav")
		var key := base
		var parts := base.rsplit("_", true, 1)
		if parts.size() == 2 and parts[1].is_valid_int():
			key = parts[0]
		if not streams.has(key):
			streams[key] = []
		streams[key].append(load("res://proto/ses/" + f))
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	amb = _loop("ambiyans", -9.0)
	drone = _loop("sisli_ugultu", -80.0)
	music = AudioStreamPlayer.new()
	if streams.has("final_muzik"):
		music.stream = streams["final_muzik"][0]
	music.volume_db = -8.0
	add_child(music)

func _loop(n: String, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if streams.has(n):
		var s: AudioStreamWAV = (streams[n][0] as AudioStreamWAV).duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
		p.stream = s
	p.volume_db = vol
	add_child(p)
	return p

func start() -> void:
	if muted:
		return
	amb.play()
	drone.play()

func play(n: String, vol_db := 0.0, pitch_var := 0.08) -> void:
	if muted or not streams.has(n):
		return
	var arr: Array = streams[n]
	for p in pool:
		if not p.playing:
			p.stream = arr[randi() % arr.size()]
			p.volume_db = vol_db
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

func _process(dt: float) -> void:
	# Sisli uğultusu ve kalp atışı tehlikeyle yükselir
	var target_db := lerpf(-40.0, -4.0, danger) if danger > 0.01 else -80.0
	drone.volume_db = move_toward(drone.volume_db, target_db, dt * 25.0)
	if danger > 0.15:
		_beat_t -= dt
		if _beat_t <= 0.0:
			_beat_t = lerpf(1.1, 0.42, danger)
			play("kalp", lerpf(-16.0, -2.0, danger), 0.02)

func final_music() -> void:
	if not muted and music.stream != null:
		music.play()
		var tw := create_tween()
		tw.tween_property(amb, "volume_db", -20.0, 4.0)
