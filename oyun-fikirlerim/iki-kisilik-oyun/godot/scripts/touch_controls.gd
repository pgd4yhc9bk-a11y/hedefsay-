class_name TouchControls extends Node
## Ekranda düğme yok. İki başparmakla, ekranın iki yarısı ayrı iş yapar:
##  SOL yarı (sol parmak): sağa/sola kaydır = yürü. Parmak sürüklendikçe başlangıç noktası onu izler.
##  SAĞ yarı (sağ parmak): yukarı kaydır = zıpla (basılı tutarsan yüksek) · kısa dokun = eşya (maske/lamba al, at, as)
##                          basılı tut = tut ve çek (sol parmakla ileri geri giderken kutuyu çekersin)
## Yürürken aynı anda zıplayabilirsin. Tek parmakla oynayan için sol parmak da yukarı kaydırınca zıplar.

const DEAD := 24.0
const JUMP_AT := 46.0
const FOLLOW := 40.0
const TAP_TIME := 0.25
const SPLIT_X := 640.0            # ekranın ortası (1280 genişlikte)

signal double_tap(pos: Vector2)   # sol yarıda çift dokunuş: Çınar'a komut (üstüne: bekle/gel, başka yere: oraya git)

var prefix := ""
var enabled := true
var fingers := {}                 # parmak no -> {"role","origin","pos","t0","moved"}
var move_id := -1
var act_id := -1
var jump_src := {"move": false, "act": false}
var grab_down := false
var _tap_release := 0
var _last_tap_t := -10.0
var _last_tap_pos := Vector2.ZERO
var _now := 0.0

func _act(n: String) -> String:
	return prefix + n

func _press(n: String, on: bool) -> void:
	var a := _act(n)
	if not InputMap.has_action(a):
		return
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)

func _set_jump(src: String, on: bool) -> void:
	jump_src[src] = on
	_press("jump", jump_src["move"] or jump_src["act"])

func release_all() -> void:
	for n in ["left", "right", "jump", "grab", "mask"]:
		_press(n, false)
	fingers.clear()
	move_id = -1
	act_id = -1
	jump_src = {"move": false, "act": false}
	grab_down = false

func _unhandled_input(e: InputEvent) -> void:
	if not enabled:
		return
	if e is InputEventScreenTouch:
		_touch(e.index, e.pressed, e.position)
	elif e is InputEventScreenDrag:
		_drag(e.index, e.position)
	elif Game.mouse_touch:   # masaüstünde fareyle deneme (--touch)
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			_touch(90, e.pressed, e.position)
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_drag(90, e.position)

func _touch(i: int, pressed: bool, pos: Vector2) -> void:
	if pressed:
		var role := "move" if pos.x < SPLIT_X else "act"
		if role == "move" and move_id >= 0:
			return
		if role == "act" and act_id >= 0:
			return
		fingers[i] = {"role": role, "origin": pos, "pos": pos, "t0": _now, "moved": false}
		if role == "move":
			move_id = i
		else:
			act_id = i
		return
	if not fingers.has(i):
		return
	var f: Dictionary = fingers[i]
	var quick: bool = (_now - float(f["t0"])) < TAP_TIME and not f["moved"]
	f["dir"] = 0
	if f["role"] == "move":
		_set_jump("move", false)
		if quick:
			if _now - _last_tap_t < 0.35 and f["pos"].distance_to(_last_tap_pos) < 70.0:
				double_tap.emit(f["pos"])
				_last_tap_t = -10.0
			else:
				_last_tap_t = _now
				_last_tap_pos = f["pos"]
		move_id = -1
	else:
		_set_jump("act", false)
		if grab_down:
			_press("grab", false)
			grab_down = false
		elif quick:
			_item_tap()
		act_id = -1
	fingers.erase(i)
	_apply_dir()

func _drag(i: int, pos: Vector2) -> void:
	if not fingers.has(i):
		return
	var f: Dictionary = fingers[i]
	f["pos"] = pos
	var off: Vector2 = pos - (f["origin"] as Vector2)
	if off.length() > 18.0:
		f["moved"] = true
	if f["role"] == "move" or (not grab_down and absf(off.x) > DEAD):   # sağ parmak da kaydırınca yürütür (tutmaya başlamadıysa)
		if absf(off.x) > FOLLOW:   # başlangıç noktası parmağı izler
			f["origin"].x = pos.x - signf(off.x) * FOLLOW
			off.x = signf(off.x) * FOLLOW
		f["dir"] = 1 if off.x > DEAD else (-1 if off.x < -DEAD else 0)
		f["walker"] = true
		_apply_dir()
	if f["role"] == "move":
		_vertical("move", f, pos, off)
	else:
		_vertical("act", f, pos, off)

func _vertical(src: String, f: Dictionary, pos: Vector2, off: Vector2) -> void:
	if off.y < -JUMP_AT:
		if not jump_src[src]:
			_set_jump(src, true)
	elif off.y > -20.0 and jump_src[src]:
		_set_jump(src, false)
		f["origin"].y = pos.y
	if off.y > 30.0:   # aşağı dönünce bir sonraki yukarı kaydırma yine zıplatsın
		f["origin"].y = pos.y - 30.0

func _apply_dir() -> void:
	# iki parmak da yürütebilir: yönü olan parmak kazanır, ikisi de varsa ekranda daha sonra hareket eden (sağ) parmak
	var d := 0
	for i in fingers:
		var fd: Dictionary = fingers[i]
		var v: int = fd.get("dir", 0)
		if v != 0:
			d = v
	_press("right", d > 0)
	_press("left", d < 0)

func _item_tap() -> void:
	_press("mask", true)
	_tap_release = 5

func _process(delta: float) -> void:
	_now += delta
	if act_id >= 0 and not grab_down and fingers.has(act_id):
		var f: Dictionary = fingers[act_id]
		if (_now - float(f["t0"])) > TAP_TIME and not f["moved"]:
			grab_down = true
			_press("grab", true)

func _physics_process(_delta: float) -> void:
	if _tap_release > 0:
		_tap_release -= 1
		if _tap_release == 0:
			_press("mask", false)
