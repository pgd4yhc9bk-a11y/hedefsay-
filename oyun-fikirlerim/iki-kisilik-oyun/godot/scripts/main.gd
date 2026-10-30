extends Node2D
## Oyun akışı: menü, bölüm yükleme, kontrol noktası, ölüm/yeniden başlama, kamera, dokunmatik düğmeler.

var levels: Array = Levels.all()
var idx := 0
var level: LevelRoot
var player: Player
var players: Array = []
var dark_on := false
var dark_layer: CanvasLayer
var dark_mat: ShaderMaterial
var glow_mat: ShaderMaterial
var cam: Camera2D
var backdrop: Backdrop
var world: Node2D
var cam_x := 0.0
var cam_y := 0.0
var look := 0.0
var state := "menu"            # menu | play | dead | win
var cp := {"pos": Vector2.ZERO, "idx": -1, "snap": {}}
var state_t := 0.0
var fade: ColorRect
var hint: Label
var menu: Control
var end_panel: Control
var touch: TouchControls
var companion: Companion
var touch_hint: Label
var rot_warn: Label

func _ready() -> void:
	backdrop = Backdrop.new()
	add_child(backdrop)
	world = Node2D.new()
	add_child(world)
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	cam.zoom = Vector2(Game.zoom, Game.zoom)
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
	dark_layer = CanvasLayer.new()
	dark_layer.layer = 6
	add_child(dark_layer)
	var dk := ColorRect.new()
	dk.size = Vector2(1280, 720)
	dk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_mat = ShaderMaterial.new()
	dark_mat.shader = load("res://shaders/dark.gdshader")
	dk.material = dark_mat
	dark_layer.add_child(dk)
	var gl := ColorRect.new()
	gl.size = Vector2(1280, 720)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_mat = ShaderMaterial.new()
	glow_mat.shader = load("res://shaders/glow.gdshader")
	gl.material = glow_mat
	dark_layer.add_child(gl)
	dark_layer.visible = false
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
	row.position = Vector2(40, 340)
	row.size = Vector2(1200, 60)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	menu.add_child(row)
	for i in levels.size():
		var b := Button.new()
		b.text = "%d  %s" % [i + 1, levels[i]["name"]] + ("\nco-op" if levels[i].get("coop", false) else "")
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
		touch = TouchControls.new()
		add_child(touch)
		touch.double_tap.connect(command_at)
		touch_hint = Label.new()
		touch_hint.text = "Bir parmakla sağa / sola kaydır: yürü   ·   yukarı kaydır: zıpla\nİkinci parmakla dokun: eşya   ·   ikinci parmağı basılı tut: tut ve çek"
		touch_hint.position = Vector2(0, 600)
		touch_hint.size = Vector2(1280, 90)
		touch_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		touch_hint.add_theme_font_size_override("font_size", 22)
		touch_hint.modulate.a = 0.0
		ui.add_child(touch_hint)
		rot_warn = Label.new()
		rot_warn.text = "Telefonu yatay çevirin"
		rot_warn.size = Vector2(1280, 720)
		rot_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rot_warn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rot_warn.add_theme_font_size_override("font_size", 40)
		rot_warn.visible = false
		ui.add_child(rot_warn)

# ---------- Çınar'a komut ----------
func command_at(screen_pos: Vector2) -> void:
	if companion == null or state != "play":
		return
	var wx := cam_x + screen_pos.x / Game.zoom
	if absf(wx - companion.me.global_position.x) < 50.0:
		companion.toggle_wait()
	else:
		companion.go_to(wx)
	Sfx.play("clink", -10.0)

func _unhandled_input(e: InputEvent) -> void:
	if companion == null or state != "play" or menu.visible:
		return
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_C:
		companion.toggle_wait()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not Game.touch_ui:
		command_at(e.position)

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
	var coop: bool = d.get("coop", false)
	players.clear()
	var kabuk := Player.new()
	kabuk.skin = d.get("hero", "kabuk")
	if coop:
		kabuk.prefix = "p1_"
	players.append(kabuk)
	if coop:
		var kul := Player.new()
		kul.skin = "kul"
		kul.prefix = "p2_"
		players.append(kul)
	elif d.get("companion", false):   # tek oyunculu: Çınar yapay zekâyla ablasının peşinden gelir
		var cin := Player.new()
		cin.skin = d.get("companion_skin", "kul")
		cin.prefix = "ai_"
		cin.size = Vector2(22, 44)
		cin.body_scale = 0.82
		cin.speed_base = 150.0
		cin.jump_v = -600.0
		players.append(cin)
	player = kabuk
	level = LevelRoot.new()
	world.add_child(level)
	for p: Player in players:
		world.add_child(p)
		p.level = level
		p.died.connect(_on_died)
	level.build(d, players)
	var start: Vector2 = d["start"]
	kabuk.global_position = start + Vector2(13, 54)
	if players.size() > 1:
		players[1].global_position = (d["start2"] as Vector2) + Vector2(13, 54)
	if companion != null:
		companion.queue_free()
		companion = null
	if d.get("companion", false):
		companion = Companion.new()
		add_child(companion)
		companion.me = players[1]
		companion.leader = players[0]
	level.exit_reached.connect(_on_exit)
	level.checkpoint_reached.connect(_on_checkpoint)
	cp = {"pos": kabuk.global_position, "idx": -1, "snap": level.snapshot()}
	dark_on = d.get("dark", false)
	dark_layer.visible = dark_on
	cam_x = 0.0
	cam_y = 0.0
	look = 0.0
	state = "play"
	state_t = 0.0
	fade.color.a = 1.0
	var h: String = d["hint"]
	var label := "%d · %s" % [i + 1, String(d["name"]).to_upper()]
	if coop:
		label += "  (co-op)"
	hint.text = label + "\n" + h
	hint.modulate.a = 1.0
	create_tween().tween_property(hint, "modulate:a", 0.0, 1.0).set_delay(4.5)
	if touch != null:
		touch.release_all()
		touch.prefix = "p1_" if coop else ""
		if i == 0 and touch_hint != null:
			touch_hint.modulate.a = 1.0
			create_tween().tween_property(touch_hint, "modulate:a", 0.0, 1.5).set_delay(7.0)

func _on_died() -> void:
	if state != "play":
		return
	state = "dead"
	state_t = 0.0
	for p: Player in players:
		if not p.dead:
			p.die()

func _on_exit() -> void:
	if state != "play":
		return
	state = "win"
	state_t = 0.0
	Sfx.play("win")

func _on_checkpoint(i: int, x: float) -> void:
	if i > cp["idx"]:
		cp = {"pos": Vector2(x, players[0].global_position.y), "idx": i, "snap": level.snapshot()}

func _respawn() -> void:
	level.restore(cp["snap"])
	for k in players.size():
		players[k].revive(cp["pos"] + Vector2(-30.0 * k, 0.0))
	state = "play"

func _process(delta: float) -> void:
	state_t += delta
	if touch != null:
		var play := state == "play" and not menu.visible
		if touch.enabled and not play:
			touch.release_all()
		touch.enabled = play
		if rot_warn != null:
			var ws := DisplayServer.window_get_size()
			rot_warn.visible = ws.y > ws.x
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
	# kamera: oyuncuya (co-op'ta iki oyuncunun ortasına) göre, baktığı yöne ileri bakış, ağır olaylarda sarsıntı
	if player != null and level != null:
		var w: float = levels[idx]["w"]
		var mid := 0.0
		for p: Player in players:
			mid += p.global_position.x
		mid /= players.size()
		var moving := absf(player.velocity.x) > 10.0
		look = lerpf(look, player.face * (90.0 if moving else 30.0), 0.02)
		var z := Game.zoom
		var vw := 1280.0 / z
		var tx := clampf(mid - vw * 0.4 + look, 0.0, maxf(0.0, w - vw))
		cam_x = lerpf(cam_x, tx, 0.07)
		# dikey: zemin ekranın alt kısmında, karakterin üstünde boşluk kalsın
		var ty := player.global_position.y - 0.70 * 720.0 / z   # karakterin ayakları ekranın %70 yüksekliğinde
		cam_y = lerpf(cam_y, clampf(ty, 0.0, 720.0 - 720.0 / z), 0.08)
		var sh := Vector2(randf() - 0.5, randf() - 0.5) * Game.shake_amt * 14.0
		cam.zoom = Vector2(z, z)
		cam.position = Vector2(cam_x + vw / 2.0, cam_y + 360.0 / z) + sh
		backdrop.update(cam_x, cam_y, z)
		if players.size() > 1:   # iki oyuncu aynı ekranda kalır: kenarlara çarpar
			for p: Player in players:
				var nx := clampf(p.global_position.x, cam_x + 24.0, cam_x + vw - 24.0)
				if nx != p.global_position.x:
					p.global_position.x = nx
					p.velocity.x = 0.0
		if dark_on and players.size() > 1:
			var kul: Player = players[1]
			var ep := kul.global_position
			if kul.rig is Rig and (kul.rig as Rig).spr.has("ember"):
				ep = (kul.rig as Rig).ember_world(kul)
			if level.lamp != null:
				ep = level.lamp.light_pos()
			level.light_pos = ep
			var fl := sin(state_t * 7.0) * 0.015 + sin(state_t * 13.0) * 0.01
			var lp := Vector2((ep.x - cam_x) * z, (ep.y - cam_y) * z)
			dark_mat.set_shader_parameter("radius", 270.0 * z)
			glow_mat.set_shader_parameter("radius", 270.0 * z)
			dark_mat.set_shader_parameter("light_px", lp)
			dark_mat.set_shader_parameter("flicker", fl)
			glow_mat.set_shader_parameter("light_px", lp)
			glow_mat.set_shader_parameter("flicker", fl)

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
		"coop_shot":
			load_level(6)
			await _wait(1.0)
			await _shot("res://../test_coop1.png")
			players[1].global_position = Vector2(1265, 520)
			players[0].global_position = Vector2(1100, 520)
			await _wait(1.2)
			await _shot("res://../test_coop2.png")
		"kul_pose":
			load_level(6)
			dark_on = false
			dark_layer.visible = false
			players[1].global_position = Vector2(300, 560)
			players[0].global_position = Vector2(200, 560)
			await _wait(1.0)
			await _shot("res://../test_kul.png")
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
		"push":
			await _t_push()
		"sibling":
			await _t_sibling()
		"zoomshot":
			load_level(10)
			players[0].override["right"] = true
			await _wait(1.6)
			players[0].override["right"] = false
			await _wait(0.8)
			await _shot("res://../test_zoom.png")
		"nehirshot":
			load_level(10)
			await _wait(1.0)
			await _shot("res://../test_nehir1.png")
			players[0].override["right"] = true
			await _wait(0.8)
			await _shot("res://../test_nehir2.png")
			await _wait(0.13)
			await _shot("res://../test_nehir2b.png")
			players[0].override["jump"] = true
			await _wait(0.25)
			await _shot("res://../test_nehir3.png")
		"ice":
			await _t_ice()
		"touch":
			await _t_touch()
		"touch2":
			await _t_touch2()
		"cayir":
			await _t_cayir()
		"cayir2":
			await _t_cayir2()
		"dbgc":
			load_level(12)
			await _wait(0.4)
			var c0 := level.crates[0]
			await _walk_auto(c0.global_position.x - 45.0)
			await _push_to(c0, 700.0)
			player.override["right"] = true
			for i in 10:
				await _wait(0.2)
				player.override["jump"] = player.is_on_wall() and player.is_on_floor()
				print("DBG x=%.1f y=%.1f vx=%.1f wall=%s floor=%s jump=%s crate=%.1f" % [player.global_position.x, player.global_position.y, player.velocity.x, player.is_on_wall(), player.is_on_floor(), player.override["jump"], c0.global_position.x])
		"touch3":
			await _t_touch3()
		"touch4":
			await _t_touch4()
		"touch5":
			await _t_touch5()
		"coop":
			await _t_c1()
			await _t_c2()
			await _t_c3()
		"c3":
			await _t_c3()
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
	_hold("grab", true)
	await _until(func() -> bool: return level.crates[0].global_position.x >= 700.0)
	await _wait(0.6)
	print("L2 kapı açıklığı=", level.doors[0]["open"], " kutu x=", level.crates[0].global_position.x)
	_hold("right", false)
	_hold("grab", false)
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

func _pwalk(p: Player, x: float) -> void:
	p.override["right"] = true
	await _until(func() -> bool: return p.global_position.x >= x or p.dead)
	p.override["right"] = false

func _pjump(p: Player, hold_sec: float, run_dir: bool = true) -> void:
	p.override["right"] = run_dir
	p.override["jump"] = true
	await _wait(hold_sec)
	p.override["jump"] = false

func _pland(p: Player) -> void:
	await _until(func() -> bool: return p.is_on_floor() or p.dead, 3.0)

func _t_c1() -> void:
	load_level(6)
	await _wait(0.5)
	var kb: Player = players[0]
	var kl: Player = players[1]
	# Kül önce geçer
	await _pwalk(kl, 985.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	print("C1 Kül ghost1: x=", kl.global_position.x, " y=", kl.global_position.y, " dead=", kl.dead)
	await _pwalk(kl, 1140.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	kl.override["right"] = false
	print("C1 Kül ghost2: x=", kl.global_position.x, " y=", kl.global_position.y, " dead=", kl.dead)
	# Kabuk geçer (Kül ortada durur)
	await _pwalk(kb, 985.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	await _pwalk(kb, 1140.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	await _pwalk(kb, 1300.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	await _pwalk(kb, 1460.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	kb.override["right"] = false
	print("C1 Kabuk karşıda: x=", kb.global_position.x, " y=", kb.global_position.y, " dead=", kb.dead)
	await _shot("res://../test_c1.png")
	# Kül devam eder
	await _pwalk(kl, 1300.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	await _pwalk(kl, 1460.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	print("C1 Kül karşıda: x=", kl.global_position.x, " dead=", kl.dead)
	await _pwalk(kb, 2440.0)
	await _pwalk(kl, 2440.0)
	await _wait(0.5)
	print("C1 bitti? lvl idx=", idx, " state=", state)

func _t_c2() -> void:
	load_level(7)
	await _wait(0.5)
	var kb: Player = players[0]
	var kl: Player = players[1]
	print("C2 başta Kabuk maske takılı: ", kb.worn)
	# Kabuk kalkanla önde, Kül arkasında
	kb.override["right"] = true
	await _until(func() -> bool:
		kl.override["right"] = kl.global_position.x < kb.global_position.x - 45.0   # Kül kalkanın arkasında kalır
		return kb.global_position.x >= 1600.0 or kb.dead, 40.0)
	kb.override["right"] = false
	await _until(func() -> bool:
		kl.override["right"] = kl.global_position.x < 1560.0
		return kl.global_position.x >= 1560.0 or kl.dead, 10.0)
	kl.override["right"] = false
	print("C2 koridor: Kabuk x=", kb.global_position.x, " dead=", kb.dead, " | Kül x=", kl.global_position.x, " dead=", kl.dead)
	await _shot("res://../test_c2.png")
	# Kabuk maskeyi duvara fırlatır (siper+basamak), ikisi de tırmanır
	await _until(func() -> bool: return arrows_gap(), 6.0)
	await _tap_p(kb, "mask")
	await _wait(1.0)
	print("C2 maske x=", level.mask.global_position.x, " Kabuk dead=", kb.dead, " Kül dead=", kl.dead)
	for p: Player in [kb, kl]:
		await _pwalk(p, level.mask.global_position.x - 50.0)
		await _pjump(p, 0.3)
		await _pland(p)
		await _pjump(p, 0.5)
		await _pland(p)
		p.override["right"] = false
	print("C2 tırmandı: Kabuk (", kb.global_position, ") Kül (", kl.global_position, ") ölü=", kb.dead or kl.dead)
	await _pwalk(kb, 2100.0)
	await _pwalk(kl, 2100.0)
	await _wait(0.5)
	print("C2 bitti? state=", state, " idx=", idx)

func arrows_gap() -> bool:
	for a in level.arrows.get_children():
		var x: float = a.global_position.x
		if x > player.global_position.x - 40.0 and x < 1760.0:
			return false
	return true

func _tap_p(p: Player, action: String) -> void:
	p.override[action] = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	p.override[action] = false
	await get_tree().physics_frame

func _t_c3() -> void:
	load_level(8)
	await _wait(0.5)
	var kb: Player = players[0]
	var kl: Player = players[1]
	print("C3 başta lamba Kül'de: ", kl.has_lamp, " durum=", level.lamp.state)
	await _pwalk(kl, 690.0)
	await _tap_p(kl, "mask")
	await _wait(1.0)
	print("C3 lamba asıldı: ", level.lamp.state, " kapı açıklığı=", level.doors[0]["open"], " Kül lamba: ", kl.has_lamp)
	await _shot("res://../test_c3a.png")
	await _pwalk(kb, 915.0)
	await _wait(0.3)
	await _tap_p(kl, "mask")
	await _wait(1.0)
	print("C3 lamba geri alındı: ", level.lamp.state, " Kül lamba: ", kl.has_lamp, " kapı açıklığı (Kapıcı tutuyor)=", level.doors[0]["open"])
	await _pwalk(kl, 1090.0)
	print("C3 Kül kapıyı geçti: x=", kl.global_position.x, " dead=", kl.dead)
	await _pjump(kl, 0.45)
	await _pland(kl)
	await _pwalk(kl, 1240.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	kl.override["right"] = false
	print("C3 Kül ghost2: ", kl.global_position, " dead=", kl.dead)
	# Kapıcı ghost1 ve ghost2'ye çıkar (Kül ghost2'de ışık tutuyor)
	await _pwalk(kb, 1090.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	await _pwalk(kb, 1240.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	kb.override["right"] = false
	print("C3 Kapıcı ghost2'de: ", kb.global_position, " dead=", kb.dead)
	# Kül öne geçer (ışık ilerler), Kapıcı ardından
	await _pwalk(kl, 1400.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	kl.override["right"] = false
	await _pwalk(kb, 1400.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	await _pwalk(kb, 1560.0)
	await _pjump(kb, 0.45)
	await _pland(kb)
	kb.override["right"] = false
	print("C3 Kapıcı ghost4'te: ", kb.global_position, " dead=", kb.dead)
	await _pwalk(kl, 1560.0)
	await _pjump(kl, 0.45)
	await _pland(kl)
	await _pwalk(kl, 1720.0)
	await _pjump(kl, 0.3)
	await _pland(kl)
	await _shot("res://../test_c3b.png")
	kl.override["right"] = false
	await _pwalk(kb, 2452.0)
	await _pwalk(kl, 2440.0)
	await _wait(0.6)
	print("C3 bitti? state=", state, " idx=", idx, " Kapıcı=", kb.global_position, " Kül=", kl.global_position, " çıkışta=", level.exit_in.size())

func _ev_touch(idx: int, pressed: bool, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.pressed = pressed
	e.position = pos
	Input.parse_input_event(e)

func _ev_drag(idx: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	Input.parse_input_event(e)

func _t_touch() -> void:
	Game.touch_ui = true
	load_level(0)
	await _wait(0.4)
	touch = TouchControls.new()
	add_child(touch)
	touch.enabled = true
	state = "play"
	var x0 := player.global_position.x
	# sağa kaydır -> yürür
	_ev_touch(0, true, Vector2(400, 400))
	await get_tree().physics_frame
	_ev_drag(0, Vector2(470, 400))
	await _wait(1.0)
	print("TOUCH sağa kaydırma: right=", Input.is_action_pressed("right"), " dx=", player.global_position.x - x0)
	# yukarı kaydır -> zıplar
	_ev_drag(0, Vector2(470, 330))
	await _wait(0.25)
	print("TOUCH yukarı kaydırma: jump=", Input.is_action_pressed("jump"), " havada=", not player.is_on_floor(), " y=", player.global_position.y)
	# başlangıç noktası parmağı izliyor: uzağa sürükle, sonra sola dön
	_ev_drag(0, Vector2(470, 400))
	await _wait(0.6)
	_ev_drag(0, Vector2(700, 400))
	await _wait(0.3)
	_ev_drag(0, Vector2(630, 400))
	await _wait(0.3)
	print("TOUCH sola dönüş (izleyen başlangıç): left=", Input.is_action_pressed("left"), " right=", Input.is_action_pressed("right"))
	_ev_touch(0, false, Vector2(640, 400))
	await _wait(0.3)
	print("TOUCH bırakınca: right=", Input.is_action_pressed("right"), " left=", Input.is_action_pressed("left"), " jump=", Input.is_action_pressed("jump"))
	# ikinci parmak: dokun -> eşya, basılı -> tut
	_ev_touch(0, true, Vector2(300, 400))
	await _wait(0.1)
	_ev_touch(1, true, Vector2(900, 400))
	await _wait(0.1)
	_ev_touch(1, false, Vector2(900, 400))
	await get_tree().physics_frame
	print("TOUCH ikinci parmak dokunuş -> mask basıldı mı: ", Input.is_action_pressed("mask"))
	await _wait(0.2)
	_ev_touch(1, true, Vector2(900, 400))
	await _wait(0.5)
	print("TOUCH ikinci parmak basılı -> grab: ", Input.is_action_pressed("grab"))
	_ev_touch(1, false, Vector2(900, 400))
	_ev_touch(0, false, Vector2(300, 400))
	await _wait(0.2)
	print("TOUCH hepsi bırakıldı: grab=", Input.is_action_pressed("grab"), " mask=", Input.is_action_pressed("mask"))

func _t_touch2() -> void:
	Game.touch_ui = true
	load_level(3)
	await _wait(0.4)
	touch = TouchControls.new()
	add_child(touch)
	touch.enabled = true
	state = "play"
	player.global_position = Vector2(160, 560)
	await _wait(0.5)
	print("TOUCH2 başta maske takılı mı: ", player.worn)
	_ev_touch(0, true, Vector2(300, 400))
	await _wait(0.1)
	_ev_touch(1, true, Vector2(900, 400))
	await _wait(0.1)
	_ev_touch(1, false, Vector2(900, 400))
	await _wait(0.4)
	print("TOUCH2 ikinci parmak dokunuşuyla maske alındı mı: ", player.worn)
	_ev_touch(1, true, Vector2(900, 400))
	await _wait(0.1)
	_ev_touch(1, false, Vector2(900, 400))
	await _wait(0.4)
	print("TOUCH2 tekrar dokunuşla fırlatıldı mı (takılı=false beklenir): ", player.worn, " maske aktif=", level.mask.active)
	_ev_touch(0, false, Vector2(300, 400))
	await _wait(0.2)
	# tek parmakla kısa dokunuş da eşya eylemi
	player.global_position = level.mask.global_position + Vector2(-34, 34)
	await _wait(0.5)
	_ev_touch(0, true, Vector2(300, 400))
	await _wait(0.08)
	_ev_touch(0, false, Vector2(300, 400))
	await _wait(0.4)
	print("TOUCH2 tek parmak kısa dokunuşla alındı mı: ", player.worn)

func _t_touch3() -> void:
	Game.touch_ui = true
	load_level(1)
	await _wait(0.4)
	touch = TouchControls.new()
	add_child(touch)
	touch.enabled = true
	state = "play"
	# sol parmak sağa kaydırır (yürür), sağ parmak yukarı kaydırır (zıplar): aynı anda
	var x0 := player.global_position.x
	_ev_touch(0, true, Vector2(200, 400))
	await get_tree().physics_frame
	_ev_drag(0, Vector2(270, 400))
	await _wait(0.4)
	_ev_touch(1, true, Vector2(900, 500))
	await get_tree().physics_frame
	_ev_drag(1, Vector2(900, 420))
	await _wait(0.2)
	print("TOUCH3 yürürken zıplama: right=", Input.is_action_pressed("right"), " jump=", Input.is_action_pressed("jump"), " havada=", not player.is_on_floor(), " dx=", player.global_position.x - x0)
	_ev_touch(1, false, Vector2(900, 420))
	_ev_touch(0, false, Vector2(270, 400))
	await _wait(1.0)
	# kutuyu çek: sağ parmak basılı (tut), sol parmak sola sürüklenir
	var crate := level.crates[0]
	player.global_position = Vector2(crate.global_position.x - 28.0 - 13.0 - 1.0, 560.0)
	player.velocity = Vector2.ZERO
	await _wait(0.5)
	var cx0 := crate.global_position.x
	_ev_touch(0, true, Vector2(400, 400))
	await get_tree().physics_frame
	_ev_touch(1, true, Vector2(900, 500))
	await _wait(0.5)
	print("TOUCH3 ikinci parmak basılı -> grab: ", Input.is_action_pressed("grab"), " tutuyor=", player.grab)
	_ev_drag(0, Vector2(330, 400))
	await _wait(1.0)
	print("TOUCH3 kutu çekildi mi: kutu x ", cx0, " -> ", crate.global_position.x, " oyuncu x=", player.global_position.x)
	_ev_drag(0, Vector2(470, 400))
	await _wait(0.8)
	print("TOUCH3 kutu itildi mi: kutu x=", crate.global_position.x, " oyuncu x=", player.global_position.x)
	_ev_touch(1, false, Vector2(900, 500))
	_ev_touch(0, false, Vector2(470, 400))

func _t_push() -> void:
	load_level(1)
	await _wait(0.4)
	var c := level.crates[0]
	var cx0 := c.global_position.x
	# tut basılı DEĞİLken kutuya yürü: kutu kıpırdamamalı
	_hold("right", true)
	await _wait(2.5)
	print("PUSH tutsuz: kutu x ", cx0, " -> ", c.global_position.x, " oyuncu x=", player.global_position.x)
	# tut basılıyken it: kutu hareket etmeli
	_hold("grab", true)
	await _wait(1.2)
	print("PUSH tutlu: kutu x=", c.global_position.x, " oyuncu x=", player.global_position.x)
	_hold("right", false)
	_hold("grab", false)

func _t_ice() -> void:
	load_level(9)
	await _wait(0.4)
	# çamurda hız
	player.global_position = Vector2(540, 560)
	await _wait(0.3)
	_hold("right", true)
	await _wait(0.8)
	print("ICE çamurda hız: vx=", player.velocity.x, " (normal 165, çamurda ~91) mud=", player.mud)
	_hold("right", false)
	# buzda kayma: yürüyüp bırak, ne kadar kayıyor
	player.global_position = Vector2(1020, 560)
	player.velocity = Vector2.ZERO
	await _wait(0.4)
	_hold("right", true)
	await _wait(1.0)
	var x1 := player.global_position.x
	print("ICE buzda hız: vx=", player.velocity.x, " on_ice=", player.on_ice)
	await _shot("res://../test_ice1.png")
	_hold("right", false)
	await _wait(1.2)
	print("ICE bırakınca kayma mesafesi: ", player.global_position.x - x1, " px (normal zeminde ~8)")
	await _shot("res://../test_ice2.png")
	# düşme animasyonu: yüksekten bırak
	player.global_position = Vector2(300, 100)
	player.velocity = Vector2.ZERO
	await _wait(0.5)
	print("ICE düşme: fall_t=", player.fall_t, " vy=", player.velocity.y)
	await _shot("res://../test_fall.png")
	await _wait(1.0)

func _t_sibling() -> void:
	load_level(10)
	await _wait(0.5)
	var nh: Player = players[0]
	var ci: Player = players[1]
	# 1) Çınar ablasının peşinden gelir
	nh.override["right"] = true
	await _until(func() -> bool: return nh.global_position.x >= 400.0)
	nh.override["right"] = false
	await _wait(1.8)
	print("SIB takip: Nehir x=", nh.global_position.x, " Çınar x=", ci.global_position.x, " mod=", companion.mode, " (yakın olmalı)")
	# 2) Çınar'ı düğmenin üstüne gönder, orada beklesin
	companion.go_to(540.0)
	await _until(func() -> bool: return companion.mode == "wait", 8.0)
	await _wait(0.5)
	print("SIB git: Çınar x=", ci.global_position.x, " mod=", companion.mode, " kapı1 açıklığı=", level.doors[0]["open"])
	# 3) Nehir kapıdan geçer
	await _pwalk(nh, 1000.0)
	print("SIB Nehir kapıyı geçti: x=", nh.global_position.x, " ölü=", nh.dead)
	# kapıda durup Çınar'ı çağır
	nh.override["right"] = false
	nh.global_position.x = 915.0
	await _wait(0.5)
	companion.toggle_wait()
	await _until(func() -> bool: return ci.global_position.x > 950.0 or ci.dead, 12.0)
	print("SIB Çınar kapıyı geçti: x=", ci.global_position.x, " ölü=", ci.dead, " mod=", companion.mode)
	# 4) ikinci kapı: altı alçak (48 px): Nehir sığmaz, Çınar sürünerek geçer
	await _pwalk(nh, 1480.0)
	await _wait(0.5)
	nh.override["right"] = true
	await _wait(1.0)
	nh.override["right"] = false
	print("SIB ikinci kapı: Nehir x=", nh.global_position.x, " (1470 civarı takılmalı)")
	companion.go_to(1610.0)
	await _until(func() -> bool: return companion.mode == "wait", 10.0)
	await _wait(0.8)
	print("SIB Çınar ikinci düğmede: x=", ci.global_position.x, " kapı2=", level.doors[1]["open"])
	await _pwalk(nh, 1700.0)
	print("SIB Nehir ikinci kapıyı geçti: x=", nh.global_position.x)
	nh.override["right"] = false
	nh.global_position.x = 1515.0
	await _wait(0.3)
	companion.toggle_wait()
	await _until(func() -> bool: return ci.global_position.x > 1560.0 and absf(ci.global_position.x - nh.global_position.x) < 120.0, 12.0)
	await _wait(0.5)
	# ikisi çıkışa
	nh.override["right"] = true
	await _until(func() -> bool: return nh.global_position.x > 2000.0, 12.0)
	nh.override["right"] = false
	await _until(func() -> bool: return ci.global_position.x > 2000.0, 12.0)
	await _until(func() -> bool: return state == "win" or idx != 10, 12.0)
	print("SIB bitti? state=", state, " Nehir=", nh.global_position.x, " Çınar=", ci.global_position.x)

func _t_touch4() -> void:
	Game.touch_ui = true
	load_level(0)
	await _wait(0.4)
	touch = TouchControls.new()
	add_child(touch)
	touch.enabled = true
	state = "play"
	var x0 := player.global_position.x
	# SAĞ başparmak sağa kaydırır: yürür
	_ev_touch(1, true, Vector2(900, 500))
	await get_tree().physics_frame
	_ev_drag(1, Vector2(960, 500))
	await _wait(0.8)
	print("TOUCH4 sağ parmak sağa: right=", Input.is_action_pressed("right"), " dx=", player.global_position.x - x0)
	# aynı parmak sola: geri yürür
	_ev_drag(1, Vector2(880, 500))
	await _wait(0.2)
	print("TOUCH4 sağ parmak sola: left=", Input.is_action_pressed("left"), " right=", Input.is_action_pressed("right"))
	_ev_touch(1, false, Vector2(880, 500))
	await _wait(0.3)
	print("TOUCH4 bırakınca: left=", Input.is_action_pressed("left"), " right=", Input.is_action_pressed("right"))
	# SOL parmak yürür, sağ parmak yukarı kaydırır (zıplar), sonra sağ parmak sola kaydırıp yönü değiştirir
	_ev_touch(0, true, Vector2(200, 400))
	await get_tree().physics_frame
	_ev_drag(0, Vector2(270, 400))
	await _wait(0.3)
	_ev_touch(1, true, Vector2(900, 500))
	await get_tree().physics_frame
	_ev_drag(1, Vector2(900, 420))
	await _wait(0.15)
	print("TOUCH4 iki parmak: right=", Input.is_action_pressed("right"), " jump=", Input.is_action_pressed("jump"))
	_ev_touch(1, false, Vector2(900, 420))
	_ev_touch(0, false, Vector2(270, 400))
	# tutmak hâlâ çalışıyor mu (sağ parmak basılı, hareket yok)
	_ev_touch(1, true, Vector2(900, 500))
	await _wait(0.5)
	print("TOUCH4 sağ basılı: grab=", Input.is_action_pressed("grab"), " right=", Input.is_action_pressed("right"))
	_ev_touch(1, false, Vector2(900, 500))

func _push_to(c: PushBody, x: float) -> void:
	player.override["grab"] = true
	player.override["right"] = true
	await _until(func() -> bool: return c.global_position.x >= x, 12.0)
	player.override["right"] = false
	player.override["grab"] = false
	await _wait(0.2)

func _hop_over() -> void:
	player.override["right"] = true
	player.override["jump"] = true
	await _wait(0.4)
	player.override["jump"] = false
	await _until(func() -> bool: return player.is_on_floor(), 2.0)

func _t_cayir() -> void:
	load_level(11)
	await _wait(0.4)
	player.override["right"] = true
	await _until(func() -> bool: return player.global_position.x >= 884.0)
	await _hop_over()
	player.override["right"] = true
	await _until(func() -> bool: return player.global_position.x >= 1275.0)
	await _hop_over()
	player.override["right"] = false
	var cr := level.crates[0]
	player.override["right"] = true
	await _until(func() -> bool: return player.global_position.x >= cr.global_position.x - 45.0)
	player.override["right"] = false
	await _push_to(cr, 1832.0)
	print("CAYIR1 kutu x=", cr.global_position.x, " Nehir x=", player.global_position.x)
	# kutunun üstüne, oradan duvara
	player.override["right"] = false
	player.global_position.x = cr.global_position.x - 50.0
	await _wait(0.3)
	player.override["right"] = true
	player.override["jump"] = true
	await _wait(0.35)
	player.override["jump"] = false
	await _until(func() -> bool: return player.is_on_floor(), 2.0)
	print("CAYIR1 kutu üstü y=", player.global_position.y, " (kutu üstü beklenen 504)")
	player.override["jump"] = true
	await _wait(0.5)
	player.override["jump"] = false
	await _until(func() -> bool: return player.is_on_floor(), 2.0)
	print("CAYIR1 duvar üstü: y=", player.global_position.y, " x=", player.global_position.x, " (üst 430)")
	await _until(func() -> bool: return player.global_position.x >= 3140.0 or player.dead, 20.0)
	await _wait(1.5)
	print("CAYIR1 bitti? idx=", idx, " state=", state, " ölü=", player.dead)

func _t_touch5() -> void:
	Game.touch_ui = true
	load_level(3)
	await _wait(0.4)
	touch = TouchControls.new()
	add_child(touch)
	touch.enabled = true
	state = "play"
	var x0 := player.global_position.x
	# birinci parmak SAĞ yarıda: yürür ve zıplar (ekran bölünmez)
	_ev_touch(0, true, Vector2(900, 400))
	await get_tree().physics_frame
	_ev_drag(0, Vector2(960, 400))
	await _wait(0.6)
	print("T5 birinci parmak sağ yarıda: right=", Input.is_action_pressed("right"), " dx=", player.global_position.x - x0)
	_ev_drag(0, Vector2(960, 330))
	await _wait(0.15)
	print("T5 aynı parmak yukarı: jump=", Input.is_action_pressed("jump"), " havada=", not player.is_on_floor())
	_ev_drag(0, Vector2(960, 400))
	await _wait(0.8)
	# ikinci parmak SOL yarıda: dokunuşla eşya (maske al)
	player.global_position.x = 150.0
	player.velocity = Vector2.ZERO
	await _wait(0.4)
	_ev_touch(1, true, Vector2(200, 500))
	await _wait(0.1)
	_ev_touch(1, false, Vector2(200, 500))
	await _wait(0.4)
	print("T5 ikinci parmak (sol yarı) dokunuş -> maske alındı mı: ", player.worn)
	# ikinci parmak basılı: grab
	_ev_touch(1, true, Vector2(200, 500))
	await _wait(0.5)
	print("T5 ikinci parmak basılı: mask=", Input.is_action_pressed("mask"), " grab=", Input.is_action_pressed("grab"))
	_ev_touch(1, false, Vector2(200, 500))
	await _wait(0.2)
	# birinci parmak kalkar, ikinci parmak yürütmeye devam eder
	_ev_touch(1, true, Vector2(300, 500))
	await get_tree().physics_frame
	_ev_touch(0, false, Vector2(960, 400))
	await get_tree().physics_frame
	_ev_drag(1, Vector2(380, 500))
	await _wait(0.3)
	print("T5 birinci kalktı, ikinci yürütür: right=", Input.is_action_pressed("right"))
	_ev_touch(1, false, Vector2(380, 500))
	await _wait(0.2)
	print("T5 hepsi kalktı: right=", Input.is_action_pressed("right"), " grab=", Input.is_action_pressed("grab"))

func _t_cayir2() -> void:
	load_level(12)
	await _wait(0.4)
	var c0 := level.crates[0]
	player.override["right"] = true
	await _until(func() -> bool: return player.global_position.x >= c0.global_position.x - 45.0)
	player.override["right"] = false
	await _push_to(c0, 700.0)
	print("CAYIR2 kutu düğmede: x=", c0.global_position.x, " kapı=", level.doors[0]["open"])
	await _wait(0.8)
	await _walk_auto(1135.0)
	print("CAYIR2 kapıyı geçti: x=", player.global_position.x, " ölü=", player.dead)
	await _hop_over()
	player.override["right"] = false
	print("CAYIR2 çukur sonrası: x=", player.global_position.x, " ölü=", player.dead)
	var c1 := level.crates[1]
	await _walk_auto(c1.global_position.x - 45.0)
	player.override["right"] = false
	await _push_to(c1, 1772.0)
	player.global_position.x = c1.global_position.x - 50.0
	await _wait(0.3)
	player.override["right"] = true
	player.override["jump"] = true
	await _wait(0.35)
	player.override["jump"] = false
	await _until(func() -> bool: return player.is_on_floor(), 2.0)
	player.override["jump"] = true
	await _wait(0.5)
	player.override["jump"] = false
	await _until(func() -> bool: return player.is_on_floor(), 2.0)
	print("CAYIR2 yüksek yer: y=", player.global_position.y, " (üst 430)")
	await _until(func() -> bool: return idx != 12 or player.dead, 25.0)
	print("CAYIR2 bitti? idx=", idx, " state=", state, " ölü=", player.dead)

func _walk_auto(tx: float) -> void:
	player.override["right"] = true
	var t0 := 0.0
	while player.global_position.x < tx and not player.dead and t0 < 20.0:
		await _wait(0.05)
		t0 += 0.05
		player.override["jump"] = player.is_on_wall() and player.is_on_floor()
		if int(t0 * 20.0) % 20 == 0:
			print("WA t=%.1f x=%.1f y=%.1f wall=%s floor=%s dead=%s right=%s" % [t0, player.global_position.x, player.global_position.y, player.is_on_wall(), player.is_on_floor(), player.dead, player.override.get("right")])
	player.override["jump"] = false
	player.override["right"] = false
	await _wait(0.2)
