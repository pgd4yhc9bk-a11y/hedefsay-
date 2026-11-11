extends Node3D
## Birinci bölümün ikinci kısmı: kurdele ağacından sonra birlikte vadiyi geçiş.
const Companion = preload("res://proto/cinar_companion.gd")
const STATIONS := [65.0, 150.0, 245.0, 345.0, 445.0, 575.0]
const GATES := [73.0, 153.0, 258.0, 360.0, 457.0, 585.0]
const NAMES := ["İki iz", "Dar geçit", "Kırık köprü", "Fenerin dili", "Terazi", "Son bağ"]
const HINTS := [
	"Çınar'ı sarı plakaya gönder. Nehir ile kolun yanına gel ve E / Kullan'a bas.",
	"Nehir dar geçide sığmıyor. Çınar'a dokun, geçidin ötesindeki sarı kola dokun.",
	"Çınar sol çarkta beklesin. Nehir sağ çarkı kullansın; köprüden önce Nehir geçsin.",
	"Çınar ışık plakasında beklesin. Fenerin gösterdiği sırayla üç taşı kullan.",
	"Kasayı büyük plakaya it. Çınar küçük plakada beklerken Nehir kolu kullansın.",
	"Üç bakır parçayı yuvalara yerleştir. Çınar sol kolu tutarken Nehir sağ kolu kullansın."
]
var player: NehirProto
var cinar: CharacterBody3D
var audio: ProtoAudio
var cam: Camera3D
var phase := "play"
var solved := [false, false, false, false, false, false]
var gates: Array[StaticBody3D] = []
var markers: Array[MeshInstance3D] = []
var crate: ProtoCrate
var bridge: StaticBody3D
var bridge_open := false
var target_marker: Node3D
var sequence: Array[int] = []
var checkpoint := 0
var selected := false
var touches := {}
var finger = null
var hint: Label
var status: Label
var clue: Label3D
var paused := false
var elapsed := 0.0
var test_mode := false
var failures := 0
var shown_station := -1
var bot_axis = null
var wood: StandardMaterial3D
var stone: StandardMaterial3D
var brass: StandardMaterial3D
var snow: StandardMaterial3D
var mobile := false
var tani := ""                    # web: adresteki tanılama seçenekleri (?hata, sade, duzenv, kayasiz, sprite0)
var tani_lbl: Label = null
var cam_dist := 14.0

func _ready() -> void:
	test_mode = "--test=birlikteanim" in OS.get_cmdline_user_args() or "--test=birlikte" in OS.get_cmdline_user_args() or "--test=birlikteplay" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String: tani = q
	tani += OS.get_environment("TANI")
	mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_environment("MOBIL") != ""
	wood = ProtoOrtam.wood_mat()
	stone = ProtoOrtam.stone_mat()
	brass = material(Color(0.42, 0.27, 0.08))   # eskimiş bakır: fener ışığında parlamasın
	brass.metallic = 0.15
	brass.roughness = 0.85
	snow = material(Color(0.2, 0.19, 0.18))   # köprü tahtaları: açık renkli eski kalas
	build_world()
	audio = ProtoAudio.new()
	add_child(audio)
	audio.muted = test_mode
	Sfx.set_ambient(false)
	if not test_mode:
		audio.start()
	player = NehirProto.new()
	player.world = self
	player.position = Vector3(4, 0.08, 0)
	add_child(player)
	player.mocap.tree.add_animation_library("cooperate", preload("res://proto/mocap/birlikte_nehir.res"))
	player.died.connect(restore_checkpoint)
	cinar = Companion.new()
	cinar.level = self
	cinar.position = Vector3(2, 0.08, 0)
	add_child(cinar)
	crate = ProtoCrate.new()
	crate.position = Vector3(432, 0.08, 0)
	crate.min_x = 430
	add_child(crate)
	cam = Camera3D.new()
	cam.fov = 30
	cam.near = 0.1
	cam.far = 400.0
	cam.position = Vector3(6, 1.35, 14)
	if mobile:   # telefon: hafif ayarlar (Kurdele bölümüyle aynı)
		player.lamp_light.shadow_enabled = false
		get_viewport().scaling_3d_scale = 0.8
		Engine.max_fps = 60
	add_child(cam)
	build_ui()
	if "--test=birlikteshot" in OS.get_cmdline_user_args():
		audio.muted = true
		run_shots()
	elif not test_mode:
		load_progress()
	else:
		if "--test=birlikteanim" in OS.get_cmdline_user_args():
			run_animation_tests()
		elif "--test=birlikteplay" in OS.get_cmdline_user_args():
			run_walkthrough()
		else:
			run_tests()

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m

func box(pos: Vector3, size: Vector3, mat: Material, solid := false, layer := 9) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = pos
	add_child(root)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		(root as StaticBody3D).collision_layer = layer
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		root.add_child(shape)
	return root

func sign_at(x: float, text: String, y := 2.4) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.012
	label.position = Vector3(x, y, -1.1)
	label.modulate = Color(0.8, 0.78, 0.7, 0.55)
	add_child(label)
	return label

func plate(x: float, width := 1.4) -> void:
	var node := box(Vector3(x, 0.025, 0), Vector3(width, 0.05, 1.4), brass)
	markers.append(node.get_child(0) as MeshInstance3D)

func lever(x: float) -> void:
	box(Vector3(x + 0.35, 0.3, 0), Vector3(0.25, 0.6, 0.35), stone)
	var arm := box(Vector3(x + 0.35, 0.75, 0), Vector3(0.08, 0.5, 0.08), brass)
	arm.rotation.z = -0.45
	box(Vector3(x + 0.46, 0.98, 0), Vector3(0.12, 0.1, 0.45), wood)

func build_world() -> void:
	if tani.contains("duzenv"):   # tanılama: sissiz düz ortam
		var e0 := Environment.new()
		e0.background_mode = Environment.BG_COLOR
		e0.background_color = Color(0.1, 0.12, 0.2)
		e0.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e0.ambient_light_color = Color(0.6, 0.6, 0.6)
		var w0 := WorldEnvironment.new()
		w0.environment = e0
		add_child(w0)
		var s0 := DirectionalLight3D.new()
		s0.rotation_degrees = Vector3(-40, 160, 0)
		add_child(s0)
	else:
		ProtoOrtam.env(self, mobile)   # Kurdele bölümüyle aynı sis ve ışık
	var ground := ProtoOrtam.ground_mat()
	# zemin: kameradan ufka kadar (çarpışma aynı yüzey, y=0)
	box(Vector3(118, -0.6, -16), Vector3(260, 1.2, 58), ground, true)
	box(Vector3(461, -0.6, -16), Vector3(406, 1.2, 58), ground, true)
	box(Vector3(-8, 2, 0), Vector3(1, 5, 3), stone, true)
	box(Vector3(662, 2, 0), Vector3(1, 5, 3), stone, true)
	var on_bos := [[-10.0, 22.0], [640.0, 662.0]]   # ön plan gövdeleri durakları ve başlangıcı kapatmasın
	for i in STATIONS.size():
		on_bos.append([STATIONS[i] - 22.0, GATES[i] + 8.0])
	ProtoOrtam.tani = tani
	if not tani.contains("sade"):
		if not tani.contains("orman0"):
			ProtoOrtam.orman(self, -10.0, 662.0, [[247.0, 259.0]], 0.0, 481, mobile, on_bos)
		if not tani.contains("yarik0"):
			_chasm(248.0, 258.0)
	for i in STATIONS.size():
		sign_at(STATIONS[i], "%d · %s" % [i + 1, NAMES[i]], 3.8)
		var gate := box(Vector3(GATES[i], 1.75, 0), Vector3(0.5, 3.5, 2.4), wood, true, 1 if i == 1 else 9) as StaticBody3D
		gates.append(gate)
		if i != 1:   # dar geçidin kapısı görünmez bir engel; görseli kaya kapı
			_dress_gate(gate)
		if i != 1:   # dar geçit kayaların arasında: taş direk yok
			for z in [-1.5, 1.5]:
				box(Vector3(GATES[i], 2, z), Vector3(0.4, 4, 0.4), stone)
	plate(60)
	plate(68)
	# Dar geçidin görsel açıklığı: altı karanlık, üstünde kaya tavanı.
	gates[1].get_child(0).visible = false
	# kaya kapı: arkada büyük kaya, iki yanda söve kayaları, üstte kapak taşı; altında çocuk boyu açıklık (1.25 m)
	for q in [[Vector3(153.1, 0.55, -2.2), Vector3(3.4, 3.0, 2.0)], [Vector3(151.55, 0.3, -0.4), Vector3(1.0, 2.1, 1.9)], [Vector3(154.5, 0.3, -0.5), Vector3(1.0, 2.2, 1.8)],
			[Vector3(153.0, 1.72, -0.5), Vector3(4.0, 1.5, 2.6)], [Vector3(150.6, 0.15, -1.6), Vector3(1.3, 1.0, 1.2)], [Vector3(155.6, 0.15, -1.3), Vector3(1.2, 0.8, 1.1)]]:
		ProtoOrtam.rock(self, q[0], q[1], 700 + int((q[0] as Vector3).x * 10.0) % 50)
	plate(158)
	plate(240)
	plate(245)
	bridge = box(Vector3(253, -0.14, 0), Vector3(10, 0.28, 2), wood, true) as StaticBody3D
	set_bridge(false)
	plate(338)
	for i in 3:
		box(Vector3(348 + i * 3, 0.65, -0.75), Vector3(0.7, 1.3, 0.4), stone)
		sign_at(348 + i * 3, ["○", "□", "△"][i], 1.6)
	clue = sign_at(343, "△  →  ○  →  □", 2.3)
	clue.visible = false
	plate(440, 2.0)
	plate(448)
	plate(453)
	plate(568)
	plate(578)
	for i in 3:
		box(Vector3(580, 0.6 + i * 0.45, -0.6), Vector3(0.2, 0.25, 0.25), brass)
	for x in [68, 158, 240, 245, 453, 568, 578]:
		lever(x)
	# Köprü tahtaları köprüyle birlikte yükselir; çarpışma tek yüzey kalır.
	for i in 20:
		var plank := box(Vector3(248.25 + i * 0.5, 0.02, 0), Vector3(0.44, 0.06, 2.0), snow)
		plank.reparent(bridge)
		plank.position = Vector3(-4.75 + i * 0.5, 0.17, 0)
	target_marker = box(Vector3.ZERO, Vector3(0.65, 0.04, 1.0), brass)
	target_marker.visible = false
	sign_at(650, "SİS\nBirinci bölümün sonu", 3.2)

## Kapı görseli: düz kutu yerine dikey kalaslar, yatay kirişler ve demir şeritler (kapıyla birlikte hareket eder)
func _dress_gate(gate: StaticBody3D) -> void:
	(gate.get_child(0) as MeshInstance3D).visible = false
	var iron := material(Color(0.09, 0.075, 0.065))
	iron.metallic = 0.6
	iron.roughness = 0.55
	var parts := []
	for k in 9:
		parts.append([Vector3(0, 0, -1.04 + k * 0.26), Vector3(0.16, 3.5, 0.24), wood])
	for y in [-1.2, 0.0, 1.2]:
		parts.append([Vector3(0.05, y, 0), Vector3(0.24, 0.18, 2.36), wood])
		parts.append([Vector3(0.05, y + 0.11, 0), Vector3(0.26, 0.04, 2.38), iron])
	for q: Array in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = q[1]
		mi.mesh = bm
		mi.material_override = q[2]
		mi.position = q[0]
		gate.add_child(mi)

## Köprü yarığı: kayalık duvarlar, arkada dolgu kayalar, dipte zifiri karanlık (Kurdele'deki uçurum gibi)
func _chasm(xa: float, xb: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var k := 0
	var z := -7.5
	while z < 6.5:
		z = maxf(z, -7.5)
		for side in [-1, 1]:
			var ex := xa if side < 0 else xb
			for row in 3:
				ProtoOrtam.rock(self, Vector3(ex + side * rng.randf_range(0.1, 0.25), -0.35 - row * 0.8 - rng.randf_range(0.0, 0.15), z + rng.randf_range(-0.15, 0.15)),
					Vector3(rng.randf_range(0.6, 0.85), rng.randf_range(0.6, 0.9), rng.randf_range(0.6, 0.9)), 900 + k, false)
				k += 1
		z += rng.randf_range(0.5, 0.7)
	for i in 4:   # dipte dökülmüş kayalar
		ProtoOrtam.rock(self, Vector3(rng.randf_range(xa + 1.5, xb - 1.5), -3.0 + rng.randf_range(-0.2, 0.2), -5.5 + i * 2.2), Vector3(rng.randf_range(1.6, 3.0), 1.4, 1.6), 950 + i, false)
	var ab := StandardMaterial3D.new()
	ab.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ab.albedo_color = Color(0.008, 0.008, 0.01)
	ab.disable_fog = true
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(xb - xa + 0.6, 22.0)
	fl.mesh = pm
	fl.material_override = ab
	fl.position = Vector3((xa + xb) * 0.5, -3.2, 2.5)
	add_child(fl)
	# yarığın yan duvarları: zemin kutusu yalnız 1.2 m kalın; altı boş kalıp arkadaki sis görünmesin
	for ex in [xa - 0.5, xb + 0.5]:
		box(Vector3(ex, -2.2, 2.5), Vector3(1.0, 2.4, 22.0), ProtoOrtam.ground_mat())
	box(Vector3((xa + xb) * 0.5, -2.2, -8.9), Vector3(xb - xa + 2.0, 2.4, 1.0), ProtoOrtam.ground_mat())   # arka duvar (zeminin altı kapalı)
	# yarık arkada kaya duvarla biter; ötesinde orman zemini sürer (ufka uzanan açık şerit kalmasın)
	box(Vector3((xa + xb) * 0.5, -0.6, -26.5), Vector3(xb - xa + 0.2, 1.2, 37.0), ProtoOrtam.ground_mat())
	for i in 7:
		ProtoOrtam.rock(self, Vector3(xa + 0.6 + i * 1.5 + rng.randf_range(-0.2, 0.2), -1.5 + rng.randf_range(-0.2, 0.2), -7.6 + rng.randf_range(-0.3, 0.3)), Vector3(rng.randf_range(1.8, 2.4), 3.2, 1.8), 970 + i, i % 2 == 0)

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	status = Label.new()
	status.position = Vector2(22, 12)
	status.add_theme_font_size_override("font_size", 22)
	ui.add_child(status)
	hint = Label.new()
	hint.position = Vector2(30, 584)
	hint.size = Vector2(1220, 65)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hint)
	var row := HBoxContainer.new()
	row.position = Vector2(22, 660)
	row.add_theme_constant_override("separation", 12)
	ui.add_child(row)
	for spec in [["Takip et · F", "follow"], ["Bekle · Q", "stay"], ["Gönder · G", "go"], ["Kullan · E", "use"], ["İpucu", "hint"], ["Duraklat", "pause"], ["Baştan", "restart"], ["Menü", "menu"]]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(120, 46)
		b.pressed.connect(action.bind(spec[1]))
		row.add_child(b)

func action(kind: String) -> void:
	if kind == "pause":
		if phase == "done": return
		paused = not paused
		phase = "paused" if paused else "play"
		player.set_physics_process(not paused)
		player.set_process(not paused)
		touches.clear()
		finger = null
		return
	if kind == "menu":
		save_progress()
		Sfx.set_ambient(true)
		get_tree().change_scene_to_file("res://main.tscn")
		return
	if kind == "restart":
		solved.fill(false)
		checkpoint = 0
		elapsed = 0.0
		shown_station = -1
		sequence.clear()
		for gate in gates:
			gate.position.y = 1.75
		set_bridge(false)
		crate.position = Vector3(432, 0.08, 0)
		phase = "play"
		paused = false
		player.set_physics_process(true)
		player.set_process(true)
		restore_checkpoint()
		save_progress()
		return
	if phase != "play":
		return
	match kind:
		"follow", "stay":
			cinar.command(kind)
			selected = false
		"go":
			cinar.command("stay")
			selected = true
		"use": interact()
		"hint": hint.text = HINTS[current_station()]

func safe_target(from: float, target: float) -> float:
	var result := clampf(target, -5, 658)
	for i in GATES.size():
		if solved[i] or i == 1 or (i == 2 and bridge_open):
			continue
		if from < GATES[i] and result > GATES[i] - 0.8:
			result = GATES[i] - 0.8
	if not bridge_open and from < 248 and result > 247:
		result = 247
	return result

func send_to(x: float) -> void:
	cinar.command("go", safe_target(cinar.position.x, x))
	selected = false

func occupied(x: float, who: Node3D, radius := 0.85) -> bool:
	return absf(who.position.x - x) < radius and absf(who.position.y) < 0.3

func companion_lever() -> bool:
	return (not solved[2] and occupied(240, cinar)) or (not solved[5] and occupied(568, cinar))

func interact() -> void:
	if phase != "play": return
	if not solved[0] and occupied(68, player, 1.5):
		if occupied(60, cinar):
			player.play_interaction("cooperate/LeverPull")
			complete(0)
		else: hint.text = "Öteki plakanın üzerinde biri beklemeli."
	elif not solved[2] and occupied(245, player, 1.5):
		if occupied(240, cinar):
			player.play_interaction("cooperate/LeverPull")
			set_bridge(true)
			hint.text = "Çınar çarkı tutsun. Karşı kıyıdaki kilidi Nehir açacak."
	elif not solved[3] and player.position.x > 346 and player.position.x < 356:
		if not occupied(338, cinar):
			hint.text = "Işık plakasını Çınar tutmalı."
			return
		var symbol := int(round((player.position.x - 348) / 3.0))
		if symbol < 0 or symbol > 2: return
		player.play_interaction("cooperate/SymbolTouch", PI / 2.0)
		var order := [2, 0, 1]
		if symbol == order[sequence.size()]:
			sequence.append(symbol)
			audio.play("cark")
			if sequence.size() == 3: complete(3)
		else:
			sequence.clear()
			hint.text = "Taşlar sustu. Fenerin sırasına yeniden bak."
	elif not solved[4] and occupied(453, player, 1.5):
		if occupied(440, crate, 0.7) and occupied(448, cinar):
			player.play_interaction("cooperate/LeverPull")
			complete(4)
		else: hint.text = "Büyük plaka ağır bir yük, küçük plaka bir yardımcı istiyor."
	elif not solved[5] and occupied(578, player, 1.5):
		if solved[0] and solved[2] and solved[3] and occupied(568, cinar):
			player.play_interaction("cooperate/LeverPull")
			complete(5)
		else: hint.text = "Üç bakır parça ve öteki kolu tutan Çınar gerekli."

func complete(i: int) -> void:
	if solved[i]: return
	solved[i] = true
	gates[i].position.y = 6.0
	checkpoint = i + 1
	audio.play("kapi_kalk", -8)
	hint.text = NAMES[i] + " tamamlandı. Çınar'ı takip etmeye çağır."
	save_progress()

func set_bridge(open: bool) -> void:
	bridge_open = open
	bridge.position.y = -0.14 if open else -8.0
	bridge.visible = open
	if gates.size() > 2:
		gates[2].position.y = 6.0 if open else 1.75

func current_station() -> int:
	for i in solved.size():
		if not solved[i]: return i
	return 5

func _process(dt: float) -> void:
	if player == null or cinar == null: return
	# yandan sinematik kamera (Kurdele bölümü gibi); bulmaca durağında açılır, iki kardeş yakınsa ortalar
	var st := current_station()
	var wide: bool = not solved[st] and absf(player.position.x - STATIONS[st]) < 17.0
	var mid := player.position.x + 1.0
	if absf(cinar.position.x - player.position.x) < 10.0:
		mid = (player.position.x + cinar.position.x) * 0.5 + 0.5
	cam_dist = lerpf(cam_dist, 20.0 if wide else 14.0, 1.0 - exp(-dt * 1.2))
	cam.position = cam.position.lerp(Vector3(mid, maxf(player.position.y, 0.0) + 1.35 + (cam_dist - 14.0) * 0.12, cam_dist), 1.0 - exp(-dt * 2.4))
	cam.rotation = Vector3(deg_to_rad(0.5 - (cam_dist - 14.0) * 0.35), 0, 0)
	if tani.contains("hata"):
		if tani_lbl == null:
			tani_lbl = Label.new()
			tani_lbl.position = Vector2(22, 60)
			tani_lbl.add_theme_font_size_override("font_size", 18)
			tani_lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			status.get_parent().add_child(tani_lbl)
		tani_lbl.text = "nehir=%s cinar=%s\nkamera=%s rot=%s guncel=%s uzak=%.1f\nfps=%d dt=%.3f mobil=%s dugum=%d cizim=%d nesne=%d" % [str(player.position.snapped(Vector3.ONE * 0.01)), str(cinar.position.snapped(Vector3.ONE * 0.01)), str(cam.position.snapped(Vector3.ONE * 0.01)), str(cam.rotation.snapped(Vector3.ONE * 0.01)), cam.current, cam_dist, Engine.get_frames_per_second(), dt, mobile, get_child_count(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)]
	status.text = "BİRLİKTE  ·  %d / 6  ·  Çınar: %s%s" % [solved.count(true), {"follow":"takip", "stay":"bekliyor", "go":"gidiyor"}[cinar.mode], "  ·  DURAKLATILDI" if paused else ""]
	target_marker.visible = phase == "play" and (selected or cinar.mode == "go")
	target_marker.position = Vector3(cinar.position.x if selected else cinar.target_x, 0.04, 0)
	if phase != "play": return
	elapsed += dt
	var nearby := current_station()
	if nearby != shown_station and absf(player.position.x - STATIONS[nearby]) < 12:
		shown_station = nearby
		hint.text = ["İki iz, tek kapı. Sarı işaretler ayak izlerine benziyor.", "Çınar kayaların altındaki açıklığa bakıyor.", "Sol çark bırakılınca köprü geri çekiliyor. Karşı kıyıda bir kilit var.", "Fenerin önündeki plaka boş. Taşların üzerindeki işaretler tanıdık.", "Bir plaka çok ağır, diğeri bir çocuk kadar hafif yük istiyor.", "Bakır parçalar yuvalara uyuyor. Son iki kol birbirinden uzak."][nearby]
	var axis := Input.get_action_strength("right") - Input.get_action_strength("left")
	if finger != null and touches.has(finger):
		var f: Dictionary = touches[finger]
		axis = clampf((f.pos.x - f.start.x) / 120.0, -1, 1)
	player.input_x = axis if bot_axis == null else float(bot_axis)
	player.grab_held = Input.is_action_pressed("grab")
	if Input.is_action_just_pressed("jump"): player.jump_pressed = true
	if not solved[1] and occupied(158, cinar): complete(1)
	if not solved[2] and bridge_open:
		if player.position.x > 260:
			complete(2)
		elif not occupied(240, cinar): set_bridge(false)
	clue.visible = occupied(338, cinar) and not solved[3]
	if selected:
		hint.text = "Çınar seçili: gitmesini istediğin zemine veya sarı işarete dokun."
	elif player.position.x < 18:
		hint.text = "Çınar'a dokun: dursun. Ardından zemine dokun: gitsin. F / Takip et: peşine gelsin. Sağa kaydır: yürü."
	if player.position.x > 648 and cinar.position.x > 645 and solved.count(true) == 6:
		phase = "done"
		player.input_x = 0
		player.state = "cut"
		cinar.command("stay")
		hint.text = "Birlikte çıktınız. Sisin ardındaki köy sizi bekliyor.  ·  Menü ile dön."

func tap(pos: Vector2) -> void:
	var screen := cam.unproject_position(cinar.position + Vector3(0, 0.65, 0))
	if screen.distance_to(pos) < 65:
		cinar.command("stay")
		selected = true
		return
	if selected:
		var origin := cam.project_ray_origin(pos)
		var direction := cam.project_ray_normal(pos)
		if absf(direction.z) > 0.001:
			var hit := origin + direction * (-origin.z / direction.z)
			send_to(hit.x)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.physical_keycode:
			KEY_F: action("follow")
			KEY_Q: action("stay")
			KEY_G: action("go")
			KEY_E: action("use")
			KEY_ESCAPE: action("pause")
	if phase != "play": return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		tap(ev.position)
	if ev is InputEventScreenTouch:
		if ev.pressed:
			var command_tap := selected or cam.unproject_position(cinar.position + Vector3(0, 0.65, 0)).distance_to(ev.position) < 65
			if command_tap:
				tap(ev.position)
				return
			touches[ev.index] = {"start":ev.position, "pos":ev.position, "jumped":false}
			if finger == null: finger = ev.index
		else:
			touches.erase(ev.index)
			if finger == ev.index: finger = null
	elif ev is InputEventScreenDrag and touches.has(ev.index):
		var f: Dictionary = touches[ev.index]
		f.pos = ev.position
		if not f.jumped and f.start.y - ev.position.y > 55:
			player.jump_pressed = true
			f.jumped = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and player != null:
		touches.clear()
		finger = null
		if phase == "play": action("pause")

func restore_checkpoint() -> void:
	var x: float = 4.0 if checkpoint == 0 else GATES[checkpoint - 1] + 4.0
	player.position = Vector3(x, 0.1, 0)
	player.velocity = Vector3.ZERO
	player.state = "ground"
	cinar.position = Vector3(x - 1.2, 0.1, 0)
	cinar.velocity = Vector3.ZERO
	cinar.reset_interaction()
	cinar.command("follow")
	player.interaction_left = 0
	selected = false
	player.input_x = 0.0
	player.jump_pressed = false
	touches.clear()
	finger = null
	if not solved[2]: set_bridge(false)
	phase = "play"

func save_progress() -> void:
	if test_mode: return
	var config := ConfigFile.new()
	config.set_value("birlikte", "solved", solved)
	config.set_value("birlikte", "elapsed", elapsed)
	config.save("user://birlikte.cfg")

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load("user://birlikte.cfg") != OK: return
	var saved = config.get_value("birlikte", "solved", [])
	if not saved is Array or saved.size() != 6: return
	for i in 6:
		if saved[i] != true: break
		solved[i] = true
		checkpoint = i + 1
		gates[i].position.y = 6.0
	if solved[2]: set_bridge(true)
	elapsed = float(config.get_value("birlikte", "elapsed", 0.0))
	restore_checkpoint()

func ground_y(x: float) -> float:
	return -8.0 if x > 248 and x < 258 and not bridge_open else 0.0
func surface_at(_p: Node3D) -> String: return "toprak"
func crate_at(p: Node3D, dir: int) -> Node:
	if crate != null and absf(p.position.y - crate.position.y) < 0.3 and absf(crate.position.x - p.position.x - dir * 0.75) < 0.25: return crate
	return null
func find_ledge(_p: NehirProto, _air: bool, _dir: float) -> Dictionary: return {}
func find_ledge_ground(p: NehirProto) -> Dictionary:
	if crate != null and absf(p.position.x - crate.position.x) < 1.1 and p.position.y < crate.top() - 0.2:
		var direction := 1 if crate.position.x > p.position.x else -1
		return {"p":Vector3(crate.position.x - direction * 0.5, crate.top(), 0), "dir":direction, "low":false, "cap":0.75}
	return {}

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("BIRLIKTE HATA: ", message)
func run_tests() -> void:
	await get_tree().create_timer(1.0).timeout
	# Dokunma yolunu doğrudan olaylarla doğrula; iPhone eksi parmak numarası kullanır.
	var touch := InputEventScreenTouch.new()
	touch.index = -7
	touch.pressed = true
	touch.position = cam.unproject_position(cinar.position + Vector3(0, 0.65, 0))
	_unhandled_input(touch)
	check(selected and cinar.mode == "stay", "Çınar'a dokunma seçip durdurmalı")
	touch.position = cam.unproject_position(Vector3(7, 0, 0))
	_unhandled_input(touch)
	check(not selected and cinar.mode == "go" and absf(cinar.target_x - 7) < 0.1, "Hedefe dokunma git komutu vermeli")
	touch.pressed = false
	_unhandled_input(touch)
	check(finger == null, "Komut dokunuşu yürüyüş parmağı olmamalı")
	action("pause")
	var stopped := player.position
	await get_tree().create_timer(0.2).timeout
	check(player.position == stopped and phase == "paused", "Duraklatma fiziği durdurmalı")
	action("pause")
	cinar.command("stay")
	var cx: float = cinar.position.x
	await get_tree().create_timer(0.3).timeout
	check(absf(cinar.position.x - cx) < 0.05, "Bekle komutu")
	send_to(7)
	await get_tree().create_timer(3.0).timeout
	check(absf(cinar.position.x - 7) < 0.2, "Git komutu")
	check(safe_target(65, 100) < 73, "Kapalı kapıdan komutla geçiş engellenmeli")
	player.position = Vector3(68, 0, 0)
	interact()
	check(not solved[0], "Yalnız oyuncu kapıyı açmamalı")
	cinar.position = Vector3(60, 0, 0)
	interact()
	check(solved[0], "İki iz")
	cinar.position = Vector3(158, 0, 0)
	await get_tree().create_timer(0.1).timeout
	check(solved[1], "Dar geçit kolu")
	cinar.command("stay")
	cinar.position = Vector3(240, 0, 0)
	player.position = Vector3(245, 0, 0)
	interact()
	check(bridge_open, "Köprü açılmalı")
	player.position.x = 261
	await get_tree().create_timer(0.1).timeout
	check(solved[2], "Karşı kıyı köprüyü kilitlemeli")
	cinar.position = Vector3(338, 0, 0)
	player.position = Vector3(348, 0, 0)
	interact()
	check(sequence.is_empty(), "Yanlış sembol sıfırlamalı")
	for x in [354, 348, 351]:
		player.position.x = x
		interact()
	check(solved[3], "Fener sırası")
	cinar.position = Vector3(448, 0, 0)
	player.position = Vector3(453, 0, 0)
	interact()
	check(not solved[4], "Kasasız terazi açılmamalı")
	crate.position = Vector3(440, 0, 0)
	interact()
	check(solved[4], "Terazi")
	cinar.position = Vector3(568, 0, 0)
	player.position = Vector3(578, 0, 0)
	interact()
	check(solved[5], "Son bağ")
	player.position.x = 650
	cinar.position.x = 648
	await get_tree().create_timer(0.1).timeout
	check(phase == "done", "Birlikte bitiş")
	action("pause")
	check(phase == "done", "Duraklat bitmiş bölümü yeniden başlatmamalı")
	action("restart")
	check(phase == "play" and solved.count(true) == 0 and checkpoint == 0 and elapsed == 0, "Baştan temiz durum kurmalı")
	print("BIRLIKTE TEST hata=", failures)
	get_tree().quit(1 if failures else 0)

## Gerçek fizik ve komutlarla güzergâh testi; konum ışınlaması kullanmaz.
func walk_to(x: float) -> void:
	var seconds := 0.0
	while phase == "play" and absf(player.position.x - x) > 0.15 and seconds < 90.0:
		bot_axis = clampf((x - player.position.x) * 1.8, -1, 1)
		await get_tree().create_timer(0.05).timeout
		seconds += 0.05
	bot_axis = 0.0
	check(seconds < 90, "Nehir hedefe ulaşamadı: " + str(x))

func guide_to(x: float) -> void:
	send_to(x)
	var seconds := 0.0
	while absf(cinar.position.x - x) > 0.2 and seconds < 30:
		await get_tree().create_timer(0.05).timeout
		seconds += 0.05
	check(seconds < 30, "Çınar hedefe ulaşamadı: " + str(x))

func run_walkthrough() -> void:
	Engine.time_scale = 6.0
	await get_tree().create_timer(1.0).timeout
	await walk_to(65)
	await guide_to(60)
	await walk_to(68)
	interact()
	cinar.command("follow")
	await walk_to(150)
	await guide_to(158)
	cinar.command("follow")
	await walk_to(243)
	await guide_to(240)
	await walk_to(245)
	interact()
	await walk_to(262)
	cinar.command("follow")
	await walk_to(335)
	await guide_to(338)
	for x in [354,348,351]:
		await walk_to(x)
		interact()
	cinar.command("follow")
	await walk_to(439.25)
	player.jump_pressed = true
	await get_tree().create_timer(1.2).timeout
	await walk_to(446)
	await guide_to(448)
	await walk_to(453)
	interact()
	cinar.command("follow")
	await walk_to(570)
	await guide_to(568)
	await walk_to(578)
	interact()
	cinar.command("follow")
	await walk_to(650)
	await get_tree().create_timer(3).timeout
	check(solved.count(true) == 6 and phase == "done", "Fizik güzergâhı bitmeli")
	print("BIRLIKTE OYNANIS hata=", failures, " oyun_saniye=", elapsed)
	get_tree().quit(1 if failures else 0)

## Yeni kliplerin kaynaklarını ve oynanıştaki geçişlerini denetle.
func run_animation_tests() -> void:
	await get_tree().create_timer(1).timeout
	for body in [player.mocap, cinar.model]:
		var lib: AnimationLibrary = body.tree.get_animation_library("cooperate")
		for name in lib.get_animation_list():
			var a: Animation = lib.get_animation(name)
			check(a.length > 0 and a.get_track_count() >= 20, "Animasyon verisi: " + name)
			check(a.loop_mode == (Animation.LOOP_LINEAR if name in ["LeverHold", "CrouchWalk"] else Animation.LOOP_NONE), "Döngü: " + name)
			for t in a.get_track_count():
				var path := a.track_get_path(t)
				check(body.model.get_node_or_null(NodePath(str(path).split(":")[0])) == body.skel, "İskelet yolu: " + name)
				check(body.skel.find_bone(path.get_subname(0)) >= 0, "Kemik yolu: " + name)
				if a.loop_mode == Animation.LOOP_LINEAR:
					var first = a.track_get_key_value(t, 0)
					var last = a.track_get_key_value(t, a.track_get_key_count(t) - 1)
					check(first.is_equal_approx(last), "Döngü dikişi: " + name)
	player.play_interaction("cooperate/LeverPull")
	await get_tree().create_timer(0.2).timeout
	check(player.mocap.any_name == "cooperate/LeverPull", "Nehir kol çekmeli")
	action("pause")
	var remaining := player.interaction_left
	await get_tree().create_timer(0.2).timeout
	check(player.interaction_left == remaining, "Duraklat animasyonu dondurmalı")
	action("pause")
	bot_axis = 1.0
	await get_tree().create_timer(0.2).timeout
	check(player.interaction_left == 0, "Yürüyüş etkileşimi iptal etmeli")
	bot_axis = 0.0
	await get_tree().create_timer(0.4).timeout
	player.play_interaction("cooperate/SymbolTouch", PI / 2)
	await get_tree().create_timer(0.2).timeout
	check(player.mocap.any_name == "cooperate/SymbolTouch", "Nehir sembole dokunmalı")
	cinar.command("stay")
	await get_tree().create_timer(0.2).timeout
	check(cinar.model.any_name == "cooperate/Nod", "Çınar onay vermeli")
	cinar.position = Vector3(240, 0, 0)
	cinar.command("stay", 0, false)
	await get_tree().create_timer(0.2).timeout
	check(cinar.lever_stage == "pull", "Çınar önce kolu çekmeli")
	await get_tree().create_timer(2.1).timeout
	check(cinar.model.any_name == "cooperate/LeverHold", "Çınar kolu tutmalı")
	cinar.command("follow")
	await get_tree().create_timer(0.2).timeout
	check(cinar.model.any_name == "cooperate/LeverRelease", "Yeni komutta kolu bırakmalı")
	await get_tree().create_timer(2.1).timeout
	check(cinar.lever_stage == "" and cinar.velocity.x < 0, "Bırakınca takibe dönmeli")
	cinar.reset_interaction()
	cinar.position = Vector3(152, 0, 0)
	cinar.command("go", 154)
	await get_tree().create_timer(0.2).timeout
	check(cinar.model.any_name == "cooperate/CrouchWalk", "Tünelde eğilmeli")
	cinar.position = Vector3(431, 0, 0)
	cinar.velocity = Vector3.ZERO
	cinar.command("go", 435)
	await get_tree().create_timer(0.2).timeout
	check(cinar.model.any_name == "cooperate/Hop", "Kasayı aşarken sıçrama klibi")
	action("restart")
	check(cinar.lever_stage == "" and player.interaction_left == 0, "Baştan eski animasyonu temizlemeli")
	print("BIRLIKTE ANIMASYON hata=", failures)
	get_tree().quit(1 if failures else 0)


## Görüntü kontrolü: başlangıç ve her durakta bir kare (xvfb ile çalıştırılır; PNG'ler proje köküne yazılır).
func run_shots() -> void:
	var spots := [6.0, 62.0, 151.0, 243.0, 344.0, 438.0, 572.0, 646.0, 247.0]
	for i in spots.size():
		player.position = Vector3(spots[i], 0.08, 0)
		cinar.position = Vector3(spots[i] - 1.4, 0.08, 0)
		cam.position = Vector3(spots[i] + 1, 1.35, 14)
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../birlikte_%d.png" % i)
	get_tree().quit()
