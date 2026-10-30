extends Node
## Genel durum: girdi eşlemesi, ekran sarsıntısı, test kipi.

var test_mode := false
var shake_amt := 0.0
var touch_ui := false

func _ready() -> void:
	_setup_inputs()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test"):
			test_mode = true
		if a == "--touch":
			touch_ui = true
	touch_ui = touch_ui or DisplayServer.is_touchscreen_available()

func _setup_inputs() -> void:
	var map := {
		"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D], "jump": [KEY_UP, KEY_W, KEY_SPACE],
		"grab": [KEY_SHIFT, KEY_E], "mask": [KEY_Q, KEY_F], "restart": [KEY_R],
		# yerel co-op testi: Kabuk (p1) oklar, Kül (p2) A D W
		"p1_left": [KEY_LEFT], "p1_right": [KEY_RIGHT], "p1_jump": [KEY_UP], "p1_grab": [KEY_SHIFT, KEY_SLASH], "p1_mask": [KEY_PERIOD],
		"p2_left": [KEY_A], "p2_right": [KEY_D], "p2_jump": [KEY_W, KEY_SPACE], "p2_grab": [], "p2_mask": [],
	}
	for action: String in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k: int in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)

func shake(a: float) -> void:
	shake_amt = maxf(shake_amt, minf(1.0, a))

func _process(delta: float) -> void:
	shake_amt = maxf(0.0, shake_amt - delta * 1.5)
