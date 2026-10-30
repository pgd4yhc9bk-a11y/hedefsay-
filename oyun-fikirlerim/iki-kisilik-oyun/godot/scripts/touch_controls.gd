class_name TouchControls extends Node
## Ekranda düğme yok, ekran bölünmez. Parmağın nerede olduğu önemsiz:
##  BİRİNCİ parmak (ilk dokunan): sağa/sola kaydır = yürü (başlangıç noktası parmağı izler) · yukarı kaydır = zıpla (basılı tutarsan yüksek)
##  İKİNCİ parmak (başka bir parmak, ekranın herhangi yeri): kısa dokun = eşya (maske/lamba al, at, as) · basılı tut = tut ve çek
##  Birinci parmak kalkarsa ikinci parmak yürütmeye devam eder.
##  Tek parmakla kısa dokunuş: eşya · tek parmakla çift dokunuş: Çınar'a komut.

const DEAD := 24.0
const JUMP_AT := 46.0
const FOLLOW := 40.0
const TAP_TIME := 0.25

signal double_tap(pos: Vector2)   # birinci parmakla çift dokunuş: Çınar'a komut (üstüne: bekle/gel, başka yere: oraya git)

var prefix := ""
var enabled := true
var fingers := {}                 # parmak no -> {"origin","pos","t0","moved","role"}
var move_id := -1
var act_id := -1
var jumping := false
var grab_down := false
var _tap_release := 0
var _last_tap_t := -10.0
var _last_tap_pos := Vector2.ZERO
var _now := 0.0
var _pending_item := -1.0

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

func release_all() -> void:
	for n in ["left", "right", "jump", "grab", "mask"]:
		_press(n, false)
	fingers.clear()
	move_id = -1
	act_id = -1
	jumping = false
	grab_down = false
	_pending_item = -1.0

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

func _stop_move() -> void:
	_press("left", false)
	_press("right", false)
	if jumping:
		jumping = false
		_press("jump", false)

func _stop_grab() -> void:
	if grab_down:
		grab_down = false
		_press("grab", false)

func _touch(i: int, pressed: bool, pos: Vector2) -> void:
	if pressed:
		var role := ""
		if move_id < 0:
			role = "move"
			move_id = i
		elif act_id < 0:
			role = "act"
			act_id = i
		else:
			return
		fingers[i] = {"role": role, "origin": pos, "pos": pos, "t0": _now, "moved": false}
		return
	if not fingers.has(i):
		return
	var f: Dictionary = fingers[i]
	var quick: bool = (_now - float(f["t0"])) < TAP_TIME and not f["moved"]
	if i == move_id:
		_stop_move()
		move_id = -1
		if quick and act_id < 0:
			if _now - _last_tap_t < 0.35 and f["pos"].distance_to(_last_tap_pos) < 70.0:
				double_tap.emit(f["pos"])   # çift dokunuş: Çınar'a komut (bekleyen tek dokunuş iptal)
				_last_tap_t = -10.0
				_pending_item = -1.0
			else:
				_last_tap_t = _now
				_last_tap_pos = f["pos"]
				_pending_item = _now + 0.36   # ikinci dokunuş gelmezse tek dokunuş = eşya (tek elle oynayan için)
		if act_id >= 0:   # ikinci parmak birinci olur
			_stop_grab()
			move_id = act_id
			act_id = -1
			var nf: Dictionary = fingers[move_id]
			nf["role"] = "move"
			nf["origin"] = nf["pos"]
			nf["moved"] = false
	elif i == act_id:
		if grab_down:
			_stop_grab()
		elif quick:
			_item_tap()
		act_id = -1
	fingers.erase(i)

func _drag(i: int, pos: Vector2) -> void:
	if not fingers.has(i):
		return
	var f: Dictionary = fingers[i]
	f["pos"] = pos
	var off: Vector2 = pos - (f["origin"] as Vector2)
	if off.length() > 18.0:
		f["moved"] = true
	if i != move_id:
		return
	if absf(off.x) > FOLLOW:   # başlangıç noktası parmağı izler: geri dönmek kolay
		f["origin"].x = pos.x - signf(off.x) * FOLLOW
		off.x = signf(off.x) * FOLLOW
	_press("right", off.x > DEAD)
	_press("left", off.x < -DEAD)
	if off.y < -JUMP_AT:
		if not jumping:
			jumping = true
			_press("jump", true)
	elif off.y > -20.0 and jumping:
		jumping = false
		_press("jump", false)
		f["origin"].y = pos.y
	if off.y > 30.0:   # aşağı dönünce bir sonraki yukarı kaydırma yine zıplatsın
		f["origin"].y = pos.y - 30.0

func _item_tap() -> void:
	_press("mask", true)
	_tap_release = 5

func _process(delta: float) -> void:
	_now += delta
	if _pending_item > 0.0 and _now >= _pending_item:
		_pending_item = -1.0
		_item_tap()
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
