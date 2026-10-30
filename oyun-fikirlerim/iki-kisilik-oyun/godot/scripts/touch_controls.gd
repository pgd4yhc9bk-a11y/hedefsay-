class_name TouchControls extends Node
## Ekranda düğme yok. Parmakla yönlendirme (Inside gibi):
##  - Birinci parmak sağa/sola kaydır: yürü (parmak sürüklendikçe başlangıç noktası onu izler, geri dönmek kolay)
##  - Birinci parmak yukarı kaydır: zıpla (basılı tutarsan yüksek, bırakırsan kısa)
##  - İkinci parmakla dokun: eşya (maske/lamba al, at, as) · ikinci parmağı basılı tut: tut ve çek
##  - Tek parmakla kısa dokunuş da eşya eylemidir

const DEAD := 24.0
const JUMP_AT := 46.0
const FOLLOW := 90.0
const TAP_TIME := 0.25

var prefix := ""
var enabled := true
var touches := {}                 # parmak no -> {"origin","pos","t0","moved"}
var primary := -1
var secondary := -1
var jump_down := false
var grab_down := false
var _tap_release := 0
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

func release_all() -> void:
	for n in ["left", "right", "jump", "grab", "mask"]:
		_press(n, false)
	touches.clear()
	primary = -1
	secondary = -1
	jump_down = false
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
		touches[i] = {"origin": pos, "pos": pos, "t0": _now, "moved": false}
		if primary < 0:
			primary = i
		elif secondary < 0:
			secondary = i
		return
	if not touches.has(i):
		return
	var t: Dictionary = touches[i]
	var quick: bool = (_now - float(t["t0"])) < TAP_TIME and not t["moved"]
	if i == primary:
		_press("left", false)
		_press("right", false)
		if jump_down:
			_press("jump", false)
			jump_down = false
		if quick and secondary < 0:
			_item_tap()
		primary = -1
		if secondary >= 0:   # ikinci parmak birinci olur
			primary = secondary
			secondary = -1
			if grab_down:
				_press("grab", false)
				grab_down = false
			touches[primary]["origin"] = touches[primary]["pos"]
	elif i == secondary:
		if grab_down:
			_press("grab", false)
			grab_down = false
		elif quick:
			_item_tap()
		secondary = -1
	touches.erase(i)

func _drag(i: int, pos: Vector2) -> void:
	if not touches.has(i):
		return
	var t: Dictionary = touches[i]
	t["pos"] = pos
	var off: Vector2 = pos - (t["origin"] as Vector2)
	if off.length() > 18.0:
		t["moved"] = true
	if i != primary:
		return
	if absf(off.x) > FOLLOW:   # başlangıç noktası parmağı izler
		t["origin"].x = pos.x - signf(off.x) * FOLLOW
		off.x = signf(off.x) * FOLLOW
	_press("right", off.x > DEAD)
	_press("left", off.x < -DEAD)
	if off.y < -JUMP_AT:
		if not jump_down:
			jump_down = true
			_press("jump", true)
	elif off.y > -20.0 and jump_down:
		jump_down = false
		_press("jump", false)
		t["origin"].y = pos.y
	if off.y > 30.0:   # aşağı dönünce bir sonraki yukarı kaydırma yine zıplatsın
		t["origin"].y = pos.y - 30.0

func _item_tap() -> void:
	_press("mask", true)
	_tap_release = 3

func _process(delta: float) -> void:
	_now += delta
	if secondary >= 0 and not grab_down and touches.has(secondary):
		var t: Dictionary = touches[secondary]
		if (_now - float(t["t0"])) > TAP_TIME and not t["moved"]:
			grab_down = true
			_press("grab", true)

func _physics_process(_delta: float) -> void:
	if _tap_release > 0:
		_tap_release -= 1
		if _tap_release == 0:
			_press("mask", false)
