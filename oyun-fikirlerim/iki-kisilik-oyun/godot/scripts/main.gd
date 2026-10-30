extends Node2D
## Oyun akışı: menü, bölüm yükleme, kontrol noktası, ölüm/yeniden başlama, kamera, dokunmatik düğmeler.

var levels: Array = Levels.all()
var idx := 0
var level: LevelRoot
var player: Player
var cam: Camera2D
var backdrop: Backdrop
var world: Node2D
var cam_x := 0.0
var look := 0.0
var state := "menu"            # menu | play | dead | win
var cp := {"pos": Vector2.ZERO, "idx": -1, "snap": {}}
var state_t := 0.0
var fade: ColorRect
var hint: Label
var menu: Control
var end_panel: Control

func _ready() -> void:
	backdrop = Backdrop.new()
	add_child(backdrop)
	world = Node2D.new()
	add_child(world)
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	_build_ui()
	load_level(0)
	state = "menu"
	menu.visible = true
	if Game.test_mode:
		_run_test()

# ---------- arayüz ----------
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	hint = Label.new()
	hint.position = Vector2(0, 90)
	hint.size = Vector2(1280, 80)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.modulate.a = 0.0
	ui.add_child(hint)
	fade = ColorRect.new()
	fade.size = Vector2(1280, 720)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)
	menu = Control.new()
	menu.size = Vector2(1280, 720)
	ui.add_child(menu)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0, 0, 0, 0.45)
	menu.add_child(shade)
	var title := Label.new()
	title.text = "S İ S"
	title.position = Vector2(0, 150)
	title.size = Vector2(1280, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	menu.add_child(title)
	var row := HBoxContainer.new()
	row.position = Vector2(240, 340)
	row.size = Vector2(800, 60)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	menu.add_child(row)
	for i in levels.size():
		var b := Button.new()
		b.text = "%d  %s" % [i + 1, levels[i]["name"]]
		b.custom_minimum_size = Vector2(120, 54)
		b.pressed.connect(func() -> void: start_level(i))
		row.add_child(b)
	var snd := Button.new()
	snd.text = "Ses: açık"
	snd.position = Vector2(560, 430)
	snd.size = Vector2(160, 46)
	snd.pressed.connect(func() -> void:
		Sfx.set_muted(not Sfx.muted)
		snd.text = "Ses: kapalı" if Sfx.muted else "Ses: açık")
	menu.add_child(snd)
	end_panel = Control.new()
	end_panel.size = Vector2(1280, 720)
	end_panel.visible = false
	ui.add_child(end_panel)
	var ep := ColorRect.new()
	ep.size = Vector2(1280, 720)
	ep.color = Color(0, 0, 0, 0.85)
	end_panel.add_child(ep)
	var el := Label.new()
	el.text = "Bölümler bitti\nSıradaki: ikinci oyuncu ve sesli co-op"
	el.size = Vector2(1280, 720)
	el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	el.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	el.add_theme_font_size_override("font_size", 28)
	end_panel.add_child(el)
	var eb := Button.new()
	eb.text = "Menü"
	eb.position = Vector2(560, 440)
	eb.size = Vector2(160, 50)
	eb.pressed.connect(func() -> void:
		end_panel.visible = false
		menu.visible = true
		state = "menu")
	end_panel.add_child(eb)
	if Game.touch_ui:
		_build_touch(ui)

func _build_touch(ui: CanvasLayer) -> void:
	var defs := [["◀", "left", Vector2(30, 600)], ["▶", "right", Vector2(150, 600)],
		["🎭", "mask", Vector2(910, 600)], ["✋", "grab", Vector2(1010, 600)], ["⤒", "jump", Vector2(1130, 600)]]
	for d: Array in defs:
		var b := Button.new()
		b.text = d[0]
		b.position = d[2]
		b.size = Vector2(100, 100)
		b.focus_mode = Control.FOCUS_NONE
		b.modulate.a = 0.6
		b.add_theme_font_size_override("font_size", 36)
		var action: String = d[1]
		b.button_down.connect(func() -> void: Input.action_press(action))
		b.button_up.connect(func() -> void: Input.action_release(action))
		ui.add_child(b)

# ---------- bölüm akışı ----------
func start_level(i: int) -> void:
	end_panel.visible = false
	menu.visible = false
	load_level(i)

func load_level(i: int) -> void:
	idx = i
	for c in world.get_children():
		c.queue_free()
	var d: Dictionary = levels[i]
	player = Player.new()
	level = LevelRoot.new()
	world.add_child(level)
	world.add_child(player)
	player.level = level
	level.build(d, player)
	var start: Vector2 = d["start"]
	player.global_position = start + Vector2(13, 54)
	player.died.connect(_on_died)
	level.exit_reached.connect(_on_exit)
	level.checkpoint_reached.connect(_on_checkpoint)
	cp = {"pos": player.global_position, "idx": -1, "snap": level.snapshot()}
	cam_x = 0.0
	look = 0.0
	state = "play"
	state_t = 0.0
	fade.color.a = 1.0
	var h: String = d["hint"]
	hint.text = "%d · %s\n%s" % [i + 1, String(d["name"]).to_upper(), h]
	hint.modulate.a = 1.0
	create_tween().tween_property(hint, "modulate:a", 0.0, 1.0).set_delay(3.5)

func _on_died() -> void:
	if state != "play":
		return
	state = "dead"
	state_t = 0.0

func _on_exit() -> void:
	if state != "play":
		return
	state = "win"
	state_t = 0.0
	Sfx.play("win")

func _on_checkpoint(i: int, x: float) -> void:
	if i > cp["idx"]:
		cp = {"pos": Vector2(x, player.global_position.y), "idx": i, "snap": level.snapshot()}

func _respawn() -> void:
	level.restore(cp["snap"])
	player.revive(cp["pos"])
	state = "play"

func _process(delta: float) -> void:
	state_t += delta
	match state:
		"dead":
			fade.color.a = move_toward(fade.color.a, 1.0, delta * 3.0)
			if state_t > 0.7:
				_respawn()
		"win":
			fade.color.a = move_toward(fade.color.a, 1.0, delta * 1.8)
			if state_t > 1.2:
				if idx + 1 < levels.size():
					load_level(idx + 1)
				else:
					state = "menu"
					end_panel.visible = true
		"play":
			fade.color.a = move_toward(fade.color.a, 0.0, delta * 1.5)
			if Input.is_action_just_pressed("restart"):
				player.die()
		"menu":
			fade.color.a = move_toward(fade.color.a, 0.0, delta * 2.0)
	# kamera: oyuncuya göre, baktığı yöne ileri bakış, ağır olaylarda sarsıntı
	if player != null and level != null:
		var w: float = levels[idx]["w"]
		var moving := absf(player.velocity.x) > 10.0
		look = lerpf(look, player.face * (90.0 if moving else 30.0), 0.02)
		var tx := clampf(player.global_position.x - 1280.0 * 0.4 + look, 0.0, w - 1280.0)
		cam_x = lerpf(cam_x, tx, 0.07)
		var sh := Vector2(randf() - 0.5, randf() - 0.5) * Game.shake_amt * 14.0
		cam.position = Vector2(cam_x + 640.0, 360.0) + sh
		backdrop.update(cam_x)

# ---------- otomatik test (ekran görüntüsü ve davranış doğrulama) ----------
func _hold(action: String, v: bool) -> void:
	player.override[action] = v

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, true).timeout

func _until(f: Callable, max_sec: float = 20.0) -> bool:
	var t := 0.0
	while t < max_sec:
		if f.call():
			return true
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return false

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func _run_test() -> void:
	var args := OS.get_cmdline_user_args()
	var which := "l1"
	for a in args:
		if a.begins_with("--test="):
			which = a.substr(7)
	await _wait(0.4)
	menu.visible = false
	match which:
		"shot":
			load_level(1)
			await _wait(1.0)
			await _shot("res://../test_shot.png")
		"dbg":
			load_level(0)
			await _wait(0.3)
			_hold("right", true)
			for i in 8:
				await _wait(0.5)
				print("x=%.1f y=%.1f vx=%.1f vy=%.1f floor=%s" % [player.global_position.x, player.global_position.y, player.velocity.x, player.velocity.y, player.is_on_floor()])
		"l1":
			load_level(0)
			await _wait(0.3)
			_hold("right", true)
			await _until(func() -> bool: return player.global_position.x > 780.0)
			_hold("jump", true)
			await _wait(0.5)
			_hold("jump", false)
			await _until(func() -> bool: return player.is_on_floor() and player.global_position.x > 870.0)
			print("L1 çukur sonrası x=", player.global_position.x, " dead=", player.dead)
			_hold("right", false)
			await _shot("res://../test_l1.png")
		"all":
			await _t_l2()
			await _t_l4()
			await _t_l5()
			await _t_l6()
	print("TEST-BITTI")
	get_tree().quit()

func _walk_to(x: float) -> void:
	_hold("right", true)
	await _until(func() -> bool: return player.global_position.x >= x or player.dead)
	_hold("right", false)

func _tap(action: String) -> void:
	_hold(action, true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_hold(action, false)
	await get_tree().physics_frame

func _jump(hold_sec: float) -> void:
	_hold("jump", true)
	await _wait(hold_sec)
	_hold("jump", false)

func _land() -> void:
	await _until(func() -> bool: return player.is_on_floor() or player.dead, 3.0)

func _t_l2() -> void:
	load_level(1)
	await _wait(0.3)
	_hold("right", true)
	await _until(func() -> bool: return level.crates[0].global_position.x >= 700.0)
	await _wait(0.6)
	print("L2 kapı açıklığı=", level.doors[0]["open"], " kutu x=", level.crates[0].global_position.x)
	_hold("right", false)
	await _shot("res://../test_l2.png")

func _t_l4() -> void:
	load_level(3)
	await _wait(0.3)
	await _walk_to(150.0)
	await _tap("mask")
	print("L4 maske takıldı: ", player.worn)
	await _walk_to(470.0)
	await _tap("mask")
	await _wait(1.2)
	print("L4 maske x=", level.mask.global_position.x, " kapı=", level.doors[0]["open"], " takılı=", player.worn)
	await _shot("res://../test_l4.png")

func _t_l5() -> void:
	load_level(4)
	await _wait(0.3)
	print("L5 başta takılı: ", player.worn)
	await _walk_to(1600.0)
	print("L5 kalkanla x=", player.global_position.x, " dead=", player.dead)
	await _shot("res://../test_l5.png")
	await _tap("mask")
	await _wait(1.0)
	await _walk_to(level.mask.global_position.x - 50.0)
	_hold("right", true)
	await _jump(0.35)
	await _land()
	print("L5 maske üstü: y=", player.global_position.y, " (maske üstü beklenen ~", 560.0 - 67.0, ")")
	await _jump(0.5)
	await _land()
	await _wait(0.5)
	_hold("right", false)
	print("L5 çıkış: x=", player.global_position.x, " y=", player.global_position.y, " dead=", player.dead)

func _t_l6() -> void:
	load_level(5)
	await _wait(0.3)
	await _walk_to(275.0)
	await _tap("mask")
	print("L6 alındı: ", player.worn, " mask aktif=", level.mask.active)
	await _walk_to(615.0)
	print("L6 atış öncesi: x=", player.global_position.x, " vx=", player.velocity.x)
	await _tap("mask")
	print("L6 atış sonrası: takılı=", player.worn, " aktif=", level.mask.active, " pos=", level.mask.global_position, " v=", level.mask.linear_velocity)
	await _wait(0.2)
	print("L6 0.2sn: pos=", level.mask.global_position, " v=", level.mask.linear_velocity)
	await _wait(1.4)
	print("L6 maske: ", level.mask.global_position, " yüzüyor mu? alt=", level.mask.global_position.y + 33.5, " (su yüzeyi ", 568.0 + 12.0, ")")
	await _shot("res://../test_l6.png")
	# karşıya geç: önce maskenin üstüne, sonra karşı kıyıya
	await _walk_to(676.0)
	_hold("right", true)
	await _jump(0.4)
	await _land()
	print("L6 maske üstü? y=", player.global_position.y, " (beklenen ~", level.mask.global_position.y - 33.5, ") dead=", player.dead)
	await _jump(0.6)
	await _land()
	_hold("right", false)
	await _wait(0.3)
	print("L6 karşıda: x=", player.global_position.x, " y=", player.global_position.y, " dead=", player.dead)
