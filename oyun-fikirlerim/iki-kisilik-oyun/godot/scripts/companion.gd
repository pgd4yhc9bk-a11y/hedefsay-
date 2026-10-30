class_name Companion extends Node
## Çınar'ın yapay zekâsı. Varsayılan olarak ablasının peşinden gelir (onun hareketlerini kısa gecikmeyle tekrarlar).
## Oyuncu onu yönlendirir: "bekle / gel" (aç-kapa) ve "şuraya git".
## Çevrimiçi co-op'ta bu denetleyici kapatılır, Çınar'ı gerçek oyuncu yönetir.

const DELAY := 0.7

var me: Player
var leader: Player
var mode := "follow"          # follow | wait | go
var target_x := 0.0
var _rec: Array = []
var _t := 0.0
var _jump_cd := 0.0
var _stuck := 0.0

func toggle_wait() -> void:
	mode = "follow" if mode == "wait" else "wait"

func go_to(x: float) -> void:
	target_x = x
	mode = "go"

func _inputs(l: bool, r: bool, j: bool) -> void:
	me.override["left"] = l
	me.override["right"] = r
	me.override["jump"] = j

func _physics_process(delta: float) -> void:
	if me == null or leader == null:
		return
	_t += delta
	_jump_cd -= delta
	_rec.append({"t": _t, "l": leader._in("left"), "r": leader._in("right"), "j": leader._in("jump"), "x": leader.global_position.x})
	while _rec.size() > 0 and _rec[0]["t"] < _t - 4.0:
		_rec.pop_front()
	if me.dead or leader.dead:
		_inputs(false, false, false)
		return
	match mode:
		"wait":
			_inputs(false, false, false)
		"go":
			_go()
		_:
			_follow()

func _follow() -> void:
	var dist := leader.global_position.x - me.global_position.x
	if absf(dist) > 900.0:   # kaybolmasın: ablasının yanına döner
		me.global_position = leader.global_position + Vector2(-50.0 * leader.face, -4.0)
		me.velocity = Vector2.ZERO
		return
	var rec: Dictionary = _rec[0] if _rec.size() > 0 else {}
	for r: Dictionary in _rec:
		if r["t"] >= _t - DELAY:
			rec = r
			break
	if rec.is_empty():
		_inputs(false, false, false)
		return
	var tx: float = rec["x"]
	var dx := tx - me.global_position.x
	var l := false
	var r := false
	var j: bool = rec["j"] and absf(dx) < 60.0
	if absf(dx) > 36.0:   # sapmışsa ablasının izine doğru yürür
		r = dx > 0.0
		l = dx < 0.0
	elif absf(dist) > 70.0:
		r = rec["r"]
		l = rec["l"]
	# duvara takılırsa zıpla
	if (l or r) and me.is_on_wall() and me.is_on_floor() and _jump_cd <= 0.0:
		j = true
		_jump_cd = 0.6
	_inputs(l, r, j)

func _go() -> void:
	var dx := target_x - me.global_position.x
	if absf(dx) < 8.0:
		mode = "wait"
		_inputs(false, false, false)
		return
	var j := false
	if me.is_on_wall() and me.is_on_floor() and _jump_cd <= 0.0:
		j = true
		_jump_cd = 0.6
	_inputs(dx < 0.0, dx > 0.0, j)
