extends Node3D
## 3. Bölüm "Değirmen": Nehir ve Çınar eski su değirmeninden geçer (HIKAYE.md, 4. perde).
## Beş eşli bulmaca: savak kapısı, kayıp dişli, testere, yük asansörü, karanlık kiler.
## Nesneler yer tutucu geometriyle kurulur; proto/modeller/<ad>.glb varsa onun yerine model yüklenir
## (liste: DEGIRMEN-MESHY-PROMPTLARI.md).
const Companion = preload("res://proto/cinar_companion.gd")
const MODEL_DIR := "res://proto/modeller/"
## Meshy modelleri önü +Z'ye bakar gelir; yandan görünen kamerada genişliği z boyunca durması gerekenler 90° döndürülür.
const MODEL_YAW := {"degirmen_kapisi": PI / 2.0, "ic_kapi": PI / 2.0, "surgulu_duvar": PI / 2.0, "degirmen_cephe": PI / 2.0, "testere_bicak": PI / 2.0, "testere_cerceve": PI / 2.0}
const STATIONS := [58.0, 104.0, 148.0, 188.0, 240.0]
const GATES := [62.0, 108.0, 162.0, 194.0, 264.0]
const NAMES := ["Savak", "Kayıp dişli", "Testere", "Yük asansörü", "Karanlık kiler"]
const HINTS := [
	"Nehir savak çarkını tutarken kapı kalkar. Çınar'ı içerideki sarı mandala gönder.",
	"Dişli duvarın ötesinde. Çınar alçak delikten geçer: onu dişliye gönder, sonra geri çağır ve mile gel, Kullan'a bas.",
	"Çınar debriyaj kolunu tutarken testere durur. Nehir geçsin ve öteki koldan testereyi kilitlesin.",
	"Nehir asansör tablasına çıksın. Çınar çıkrığı tutunca tabla yükselir. Yukarıdaki kol kapıyı açar.",
	"Çınar karanlıkta yalnız kalamaz. Nehir lambaları yaksın; Çınar çarkı tutarken Nehir kolu çeksin."
]
const INTRO := [
	"Kapı ağır. Su çarkı dönmüyor; savağın el çarkı dışarıda.",
	"Mil boş dönüyor: bir dişli eksik. Duvarın dibinde çocuk boyu bir delik var.",
	"Testere durmadan inip kalkıyor. Yanında bir debriyaj kolu var.",
	"Kapı içeriden sürgülü. Yukarıda bir çatı katı, yanında yük asansörü var.",
	"Kiler zifiri karanlık. Çınar eşikte duruyor."
]
const WINCH_X := 180.0
const LIFT_X := 186.0
const LOFT_Y := 1.7
const LOFT_A := 186.9
const LOFT_B := 200.0
const SAW_X := 150.0
const DARK_A := 218.0
const DARK_B := 262.0
const LAMPS := [230.0, 250.0]
const LIGHT_R := 7.0
const END_X := 300.0
const PARCA := 48.0
const GORUS := 70.0

var player: NehirProto
var cinar: CharacterBody3D
var audio: ProtoAudio
var cam: Camera3D
var crate: ProtoCrate = null        # bu bölümde kasa yok (Çınar ve Nehir kodu soruyor)
var phase := "play"
var solved := [false, false, false, false, false]
var gates: Array[StaticBody3D] = []
var gate_y: Array[float] = []
var checkpoint := 0
var selected := false
var touches := {}
var finger = null
var hint: Label
var status: Label
var paused := false
var elapsed := 0.0
var test_mode := false
var failures := 0
var shown_station := -1
var bot_axis = null
var wood: StandardMaterial3D
var stone: StandardMaterial3D
var brass: StandardMaterial3D
var iron: StandardMaterial3D
var plank: StandardMaterial3D
var wall: StandardMaterial3D
var mobile := false
var cam_dist := 14.0
var env: Environment
var sun: DirectionalLight3D
var parcalar := {}                  # süs parçaları: yalnız kameraya yakın olanlar çizilir
var target_marker: Node3D
var hold0 := false                  # Nehir savak çarkını tutuyor
var water_wheel: Node3D
var sluice_wheel: Node3D
var gear_state := "floor"           # floor | carried | mounted
var gear: Node3D
var gears: Array[Node3D] = []
var saw: Node3D
var saw_t := 0.0
var lift: AnimatableBody3D
var lift_y := 0.0
var lamp_lit := [false, false]
var lamp_lights: Array[OmniLight3D] = []
var hurt_t := 0.0
var done_t := 0.0
var fade: ColorRect

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	test_mode = "--test=degirmen" in args or "--test=degirmenplay" in args
	mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_environment("MOBIL") != ""
	wood = ProtoOrtam.wood_mat()
	stone = ProtoOrtam.stone_mat()
	brass = material(Color(0.42, 0.27, 0.08))
	brass.metallic = 0.15
	brass.roughness = 0.85
	iron = material(Color(0.085, 0.075, 0.07))
	iron.metallic = 0.6
	iron.roughness = 0.55
	plank = ProtoOrtam.wood_mat()
	plank.albedo_color = Color(0.3, 0.25, 0.2)
	wall = ProtoOrtam.wood_mat()
	wall.albedo_color = Color(0.24, 0.2, 0.17)
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
	cinar.position = Vector3(2.7, 0.08, 0)
	add_child(cinar)
	cam = Camera3D.new()
	cam.fov = 30
	cam.near = 0.1
	cam.far = 400.0
	cam.position = Vector3(6, 1.35, 14)
	if mobile:
		player.lamp_light.shadow_enabled = false
		get_viewport().scaling_3d_scale = 0.8
		Engine.max_fps = 60
	add_child(cam)
	build_ui()
	if "--test=degirmenshot" in args:
		audio.muted = true
		run_shots()
	elif "--test=degirmenplay" in args:
		run_walkthrough()
	elif "--test=degirmen" in args:
		run_tests()
	else:
		load_progress()

# ------------------------------------------------------------------ yapı taşları
func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m

## Süs parçası: x'e göre 48 m'lik dilimin düğümü (uzaktaki dilimler gizlenir; web'de nesne sayısı sınırı)
func deko(x: float) -> Node3D:
	var k := int(floor(x / PARCA))
	if not parcalar.has(k):
		var n := Node3D.new()
		add_child(n)
		parcalar[k] = n
	return parcalar[k]

func _gorunur(cx: float) -> void:
	for k: int in parcalar:
		var a := float(k) * PARCA
		(parcalar[k] as Node3D).visible = a + PARCA + 10.0 > cx - GORUS and a - 10.0 < cx + GORUS

func mesh_box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

## Silindir; ekseni z (kameraya dönük teker) ya da y (dik)
func mesh_cyl(parent: Node, pos: Vector3, r: float, h: float, mat: Material, axis_z := true, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	if axis_z:
		mi.rotation.x = PI / 2.0
	parent.add_child(mi)
	return mi

## Çarpışmalı kutu (kapı, duvar, zemin). layer 9: herkes; 1: yalnız Nehir (Çınar geçer)
func solid(pos: Vector3, size: Vector3, mat: Material, layer := 9, visible_mesh := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = layer
	add_child(body)
	if visible_mesh:
		mesh_box(body, Vector3.ZERO, size, mat)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	return body

func _aabb_of(n: Node, xf: Transform3D) -> Array:   # [AABB, var mı]
	var out := AABB()
	var has := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = xf * (n as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in n.get_children():
		if c is Node3D:
			var r: Array = _aabb_of(c, xf * (c as Node3D).transform)
			if r[1]:
				out = out.merge(r[0]) if has else r[0]
				has = true
	return [out, has]

## Model yuvası: proto/modeller/<ad>.glb varsa yüklenir (yüksekliği h olacak şekilde ölçeklenir,
## tabanı ya da merkezi pivota oturur); yoksa yedek() yer tutucuyu kurar. Dönen pivotu hareket ettir.
func prop(ad: String, pos: Vector3, h: float, yedek: Callable, parent: Node = null, merkez := false, yaw := 0.0) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	(parent if parent != null else deko(pos.x)).add_child(pivot)
	var path := MODEL_DIR + ad + ".glb"
	if ResourceLoader.exists(path):
		var rot := Node3D.new()
		rot.rotation.y = yaw + float(MODEL_YAW.get(ad, 0.0))
		pivot.add_child(rot)
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		rot.add_child(inst)
		var r: Array = _aabb_of(inst, Transform3D.IDENTITY)
		if r[1]:
			var ab: AABB = r[0]
			var s := h / maxf(ab.size.y, 0.001)
			var c := ab.get_center()
			inst.scale = Vector3.ONE * s
			inst.position = -Vector3(c.x, c.y if merkez else ab.position.y, c.z) * s
		pivot.set_meta("model", true)
	else:
		yedek.call(pivot)
	return pivot

func sign_at(x: float, text: String, y := 2.4) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 36
	label.pixel_size = 0.012
	label.position = Vector3(x, y, -1.1)
	label.modulate = Color(0.8, 0.78, 0.7, 0.55)
	deko(x).add_child(label)
	return label

func plate(x: float, width := 1.4) -> void:
	mesh_box(deko(x), Vector3(x, 0.025, 0), Vector3(width, 0.05, 1.4), brass)

func lever(x: float, y := 0.0) -> void:
	prop("kol", Vector3(x + 0.35, y, -0.55), 1.1, func(p: Node3D) -> void:
		mesh_box(p, Vector3(0, 0.3, 0), Vector3(0.25, 0.6, 0.35), stone)
		var arm := mesh_box(p, Vector3(0, 0.75, 0), Vector3(0.08, 0.5, 0.08), brass)
		arm.rotation.z = -0.45
		mesh_box(p, Vector3(0.11, 0.98, 0), Vector3(0.12, 0.1, 0.3), wood))

## Dişli/teker yer tutucusu: z eksenli disk + dişler
func _wheel(p: Node3D, r: float, teeth: int, mat: Material, thick := 0.22) -> void:
	mesh_cyl(p, Vector3.ZERO, r, thick, mat, true, 20)
	mesh_cyl(p, Vector3.ZERO, r * 0.22, thick + 0.12, iron, true, 10)
	for i in teeth:
		var a := TAU * float(i) / float(teeth)
		var t := mesh_box(p, Vector3(cos(a), sin(a), 0) * (r + 0.07), Vector3(0.2, 0.16, thick), mat)
		t.rotation.z = a

# ------------------------------------------------------------------ dünya
func build_world() -> void:
	var ev: Array = ProtoOrtam.env(self, mobile)
	env = ev[0]
	sun = ev[1]
	var ground := ProtoOrtam.ground_mat()
	solid(Vector3(150, -0.6, -16), Vector3(330, 1.2, 58), ground)
	solid(Vector3(-8, 2, 0), Vector3(1, 5, 3), stone)
	solid(Vector3(END_X + 4, 2, 0), Vector3(1, 5, 3), stone, 9, false)
	# dışarıdaki orman (değirmenin önü ve arkası), parçalar hâlinde
	for seg: Array in [[-10.0, 44.0, 0], [268.0, END_X + 10.0, 1]]:
		var x0: float = seg[0]
		while x0 < seg[1]:
			var x1 := minf(x0 + PARCA, seg[1])
			ProtoOrtam.orman(deko(x0 + 1.0), x0, x1, [], 0.0, 733 + int(x0), mobile, [[-10.0, 30.0], [280.0, END_X + 10.0]])
			x0 = x1
	_build_stream()
	_build_mill()
	for i in STATIONS.size():
		var gh := 1.4 if i == 3 else 3.5   # 4. kapı çatı katının altında kalır (üstünden Nehir geçer)
		var g := solid(Vector3(GATES[i], gh * 0.5, 0), Vector3(0.5, gh, 2.4), wood, 1 if i == 1 else 9, false)
		gates.append(g)
		gate_y.append(gh * 0.5)
		_dress_gate(g, i)
	_puzzle_savak()
	_puzzle_disli()
	_puzzle_testere()
	_puzzle_asansor()
	_puzzle_kiler()
	_build_exit()
	target_marker = mesh_box(self, Vector3.ZERO, Vector3(0.65, 0.04, 1.0), brass)
	target_marker.visible = false
	_gorunur(4.0)

func _dress_gate(gate: StaticBody3D, i: int) -> void:
	var names := ["degirmen_kapisi", "surgulu_duvar", "ic_kapi", "ic_kapi", "degirmen_kapisi"]
	var gh := 1.4 if i == 3 else 3.5
	prop(names[i], Vector3(0, -gh * 0.5, 0), gh, func(p: Node3D) -> void:
		for k in 9:
			mesh_box(p, Vector3(0, gh * 0.5, -1.04 + k * 0.26), Vector3(0.16, gh, 0.24), wood)
		for y in [gh * 0.16, gh * 0.5, gh * 0.84]:
			mesh_box(p, Vector3(0.05, y, 0), Vector3(0.24, 0.18, 2.36), wood)
			mesh_box(p, Vector3(0.05, y + 0.11, 0), Vector3(0.26, 0.04, 2.38), iron)
		if i == 1:   # alt köşede çocuk boyu delik (koyu)
			var hole := material(Color(0.005, 0.005, 0.006))
			hole.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mesh_box(p, Vector3(0, 0.45, 0.35), Vector3(0.3, 0.9, 0.9), hole), gate)

## Dere ve su çarkı (değirmenin dışı)
func _build_stream() -> void:
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.05, 0.075, 0.09)
	wm.roughness = 0.15
	wm.metallic = 0.4
	var d := deko(50.0)
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5.0, 40.0)
	w.mesh = pm
	w.material_override = wm
	w.position = Vector3(50.5, 0.015, -22.0)
	d.add_child(w)
	for sx in [47.8, 53.2]:   # kıyı taşları
		for k in 6:
			ProtoOrtam.rock(d, Vector3(sx + sin(k * 2.1) * 0.3, -0.1, -2.6 - k * 2.4), Vector3(1.2, 0.55, 1.5), 300 + k + int(sx))
	# oluk: sudan çarka inen tahta kanal
	prop("su_olugu", Vector3(50.5, 0.0, -3.3), 3.6, func(p: Node3D) -> void:
		var trough := mesh_box(p, Vector3(-1.2, 3.25, 0), Vector3(6.0, 0.25, 0.9), wood)
		trough.rotation.z = -0.08
		for x in [-3.6, -1.2, 1.0]:
			mesh_box(p, Vector3(x, 1.6, 0), Vector3(0.22, 3.2, 0.22), wood))
	water_wheel = prop("su_carki", Vector3(54.5, 2.6, -3.3), 5.0, func(p: Node3D) -> void:
		mesh_cyl(p, Vector3.ZERO, 0.3, 1.4, iron, true, 10)
		for i in 12:
			var a := TAU * float(i) / 12.0
			var spoke := mesh_box(p, Vector3(cos(a), sin(a), 0) * 1.2, Vector3(2.4, 0.12, 0.14), wood)
			spoke.rotation.z = a
			var pad := mesh_box(p, Vector3(cos(a), sin(a), 0) * 2.3, Vector3(0.12, 0.7, 1.1), wood)
			pad.rotation.z = a
		for rr in [2.05, 2.45]:
			for i in 24:
				var a := TAU * (float(i) + 0.5) / 24.0
				var rim := mesh_box(p, Vector3(cos(a), sin(a), 0) * rr, Vector3(0.1, rr * 0.27, 1.0), wood)
				rim.rotation.z = a, self, true)

## Değirmen binası: arka duvar, döşeme, direkler, kirişler, pencereler, süs eşyaları
func _build_mill() -> void:
	var dark := material(Color(0.055, 0.045, 0.04))
	var pane := material(Color(0.5, 0.55, 0.6))
	pane.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var x := 62.0
	while x < 264.0:
		var x1 := minf(x + 8.0, 264.0)
		var mid := (x + x1) * 0.5
		var d := deko(mid)
		var karanlik := mid > DARK_A - 4.0
		mesh_box(d, Vector3(mid, 3.5, -2.9), Vector3(x1 - x, 7.0, 0.3), wall)              # arka duvar
		mesh_box(d, Vector3(mid, 0.03, -0.3), Vector3(x1 - x, 0.06, 5.0), plank)            # döşeme
		mesh_box(d, Vector3(x, 3.5, -2.65), Vector3(0.35, 7.0, 0.35), dark)                 # direk
		mesh_box(d, Vector3(mid, 5.6, -1.4), Vector3(x1 - x, 0.35, 0.35), dark)             # boyuna kiriş
		mesh_box(d, Vector3(x, 5.6, -0.4), Vector3(0.3, 0.3, 5.0), dark)                    # enine kiriş
		mesh_box(d, Vector3(mid, 7.2, -0.4), Vector3(x1 - x, 0.3, 6.0), dark)               # çatı
		if not karanlik and int(x) % 16 == 14:                                              # pencere (soğuk ışık)
			mesh_box(d, Vector3(mid, 3.3, -2.72), Vector3(1.1, 1.4, 0.06), pane)
			mesh_box(d, Vector3(mid, 3.3, -2.68), Vector3(0.08, 1.4, 0.08), dark)
			mesh_box(d, Vector3(mid, 3.3, -2.68), Vector3(1.1, 0.08, 0.08), dark)
			var wl := OmniLight3D.new()
			wl.light_color = Color(0.62, 0.7, 0.82)
			wl.light_energy = 7.0
			wl.omni_range = 14.0
			wl.omni_attenuation = 1.1
			wl.position = Vector3(mid, 3.2, -1.2)
			d.add_child(wl)
		x = x1
	# dış cepheler (ön ve arka duvarın kapı üstü)
	for gx in [62.0, 264.0]:
		prop("degirmen_cephe", Vector3(gx, 0.0, -1.2), 7.4, func(p: Node3D) -> void:
			mesh_box(p, Vector3(0, 5.45, 0.4), Vector3(0.5, 3.9, 5.6), wood)
			mesh_box(p, Vector3(0, 1.75, -1.75), Vector3(0.5, 3.5, 1.1), wood)
			mesh_box(p, Vector3(0, 7.5, 0.4), Vector3(1.2, 0.3, 6.4), dark))
	# süs: çuvallar, fıçılar, değirmen taşı, tomruklar
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for sx in [72.0, 78.5, 90.0, 122.0, 131.0, 170.0, 208.0, 222.0, 244.0]:
		for k in rng.randi_range(2, 4):
			var px: float = sx + k * 0.75 + rng.randf_range(-0.1, 0.1)
			var pz := -2.1 + rng.randf_range(-0.2, 0.3)
			if rng.randf() < 0.55:
				prop("un_cuvali", Vector3(px, 0.06, pz), 0.85, func(p: Node3D) -> void:
					var sack := mesh_cyl(p, Vector3(0, 0.42, 0), 0.3, 0.85, material(Color(0.3, 0.27, 0.21)), false, 10)
					sack.scale = Vector3(1.0, 1.0, 0.75))
			else:
				prop("fici", Vector3(px, 0.06, pz), 1.0, func(p: Node3D) -> void:
					mesh_cyl(p, Vector3(0, 0.5, 0), 0.36, 1.0, wood, false, 12)
					for y in [0.2, 0.8]:
						mesh_cyl(p, Vector3(0, y, 0), 0.375, 0.06, iron, false, 12))
	prop("degirmen_tasi", Vector3(84.0, 0.06, -1.6), 1.7, func(p: Node3D) -> void:
		mesh_cyl(p, Vector3(0, 0.35, 0), 1.0, 0.7, wood, false, 14)
		mesh_cyl(p, Vector3(0, 0.9, 0), 0.85, 0.3, stone, false, 18)
		mesh_cyl(p, Vector3(0, 1.22, 0), 0.85, 0.3, stone, false, 18)
		mesh_cyl(p, Vector3(0, 2.4, 0), 0.07, 2.2, iron, false, 8)
		mesh_box(p, Vector3(0.6, 1.9, 0), Vector3(0.7, 0.8, 0.7), wood))
	for k in 5:   # bıçkıhane tomrukları
		prop("tomruk", Vector3(143.0 + (k % 3) * 0.1, 0.3 + (k / 3) * 0.5, -2.0 + (k % 3) * 0.55 - (k / 3) * 0.3), 0.5, func(p: Node3D) -> void:
			var lg := mesh_cyl(p, Vector3(0, 0.25, 0), 0.25, 3.6, ProtoOrtam.bark_mat(), false, 10)
			lg.rotation.z = PI / 2.0)

func _puzzle_savak() -> void:
	sign_at(STATIONS[0], "1 · Savak", 3.9)
	sluice_wheel = prop("el_carki", Vector3(56.0, 1.15, -0.7), 1.1, func(p: Node3D) -> void:
		_wheel(p, 0.48, 8, iron, 0.08)
		mesh_box(p, Vector3(0.3, 0.2, 0.12), Vector3(0.07, 0.07, 0.22), wood), self, true)
	mesh_box(deko(56.0), Vector3(56.0, 0.58, -0.85), Vector3(0.3, 1.15, 0.25), wood)
	plate(56.0, 1.2)
	plate(67.0)
	lever(67.0)

func _puzzle_disli() -> void:
	sign_at(STATIONS[1], "2 · Kayıp dişli", 3.9)
	# dişli takımı: büyük dişli dönüyor, ortadaki mil boş, sağdaki küçük dişli duruyor
	mesh_box(deko(100.0), Vector3(100.0, 1.6, -1.55), Vector3(4.2, 3.2, 0.25), material(Color(0.07, 0.06, 0.05)))
	gears.append(prop("disli", Vector3(98.7, 1.9, -1.2), 2.0, func(p: Node3D) -> void: _wheel(p, 0.92, 14, wood), self, true))
	mesh_cyl(deko(100.0), Vector3(100.05, 1.25, -1.25), 0.07, 0.6, iron, true, 8)   # boş mil
	gears.append(prop("disli", Vector3(101.15, 1.75, -1.2), 1.1, func(p: Node3D) -> void: _wheel(p, 0.5, 9, wood), self, true))
	plate(100.0, 1.2)
	gear = prop("disli", Vector3(116.0, 0.45, -0.5), 0.8, func(p: Node3D) -> void: _wheel(p, 0.36, 8, brass, 0.14), self, true)
	plate(116.0, 1.0)
	# duvarın ötesi: Çınar'ın sürünerek geçtiği alçak geçit (üstü raflı)
	for k in 3:
		mesh_box(deko(108.0), Vector3(108.0, 1.25 + k * 0.75, 0.2), Vector3(3.0, 0.1, 1.6), wood)

func _puzzle_testere() -> void:
	sign_at(STATIONS[2], "3 · Testere", 3.9)
	plate(140.0)
	lever(140.0)
	lever(157.0)
	plate(157.0, 1.2)
	# testere çerçevesi (sabit) ve inip kalkan bıçak
	prop("testere_cerceve", Vector3(SAW_X, 0.0, 0.0), 4.2, func(p: Node3D) -> void:
		for z in [-1.25, 1.25]:
			mesh_box(p, Vector3(0, 2.1, z), Vector3(0.35, 4.2, 0.3), wood)
		mesh_box(p, Vector3(0, 4.1, 0), Vector3(0.4, 0.35, 2.8), wood)
		mesh_box(p, Vector3(0, 0.25, -2.0), Vector3(3.6, 0.5, 1.0), wood))
	saw = prop("testere_bicak", Vector3(SAW_X, 1.6, 0.0), 2.6, func(p: Node3D) -> void:
		mesh_box(p, Vector3(0, 0, 0), Vector3(0.04, 2.6, 0.5), material(Color(0.32, 0.33, 0.35)))
		mesh_box(p, Vector3(0, 1.35, 0), Vector3(0.14, 0.14, 2.3), iron)
		mesh_box(p, Vector3(0, -1.35, 0), Vector3(0.14, 0.14, 2.3), iron)
		for k in 12:
			var tooth := mesh_box(p, Vector3(0, -1.2 + k * 0.2, 0.27), Vector3(0.04, 0.12, 0.12), material(Color(0.32, 0.33, 0.35)))
			tooth.rotation.x = PI / 4.0, self, true)

func _puzzle_asansor() -> void:
	sign_at(STATIONS[3], "4 · Yük asansörü", 4.6)
	plate(WINCH_X)
	prop("cikrik", Vector3(WINCH_X + 0.4, 0.06, -0.75), 1.3, func(p: Node3D) -> void:
		for z in [-0.35, 0.35]:
			mesh_box(p, Vector3(0, 0.55, z), Vector3(0.14, 1.1, 0.1), wood)
		var drum := mesh_cyl(p, Vector3(0, 0.95, 0), 0.16, 0.6, wood, true, 10)
		drum.rotation.x = PI / 2.0
		mesh_box(p, Vector3(0, 0.95, 0.5), Vector3(0.06, 0.5, 0.06), iron))
	# tabla (yalnız Nehir'i taşır; Çınar çarpmadan altından geçer)
	lift = AnimatableBody3D.new()
	lift.collision_layer = 1
	lift.sync_to_physics = false
	lift.position = Vector3(LIFT_X, -0.06, 0)
	add_child(lift)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.7, 0.2, 2.0)
	cs.shape = bs
	lift.add_child(cs)
	prop("asansor_tablasi", Vector3(0, -0.1, 0), 0.2, func(p: Node3D) -> void:
		mesh_box(p, Vector3(0, 0.1, 0), Vector3(1.7, 0.2, 2.0), plank)
		for sx in [-0.8, 0.8]:
			mesh_box(p, Vector3(sx, 0.22, 0), Vector3(0.1, 0.06, 2.0), iron), lift)
	for z in [-0.95, 0.95]:   # zincirler tablayla birlikte uzar
		mesh_box(lift, Vector3(0, 3.0, z), Vector3(0.05, 6.0, 0.05), iron)
	# çatı katı
	var loft := solid(Vector3((LOFT_A + LOFT_B) * 0.5, LOFT_Y - 0.125, -0.2), Vector3(LOFT_B - LOFT_A, 0.25, 4.4), plank, 1)
	for lx in [LOFT_A + 0.2, 193.4, LOFT_B - 0.2]:
		mesh_box(loft, Vector3(lx - (LOFT_A + LOFT_B) * 0.5, -0.9, -2.0), Vector3(0.25, 1.6, 0.25), wood)
	mesh_box(loft, Vector3(0, 0.95, -2.1), Vector3(LOFT_B - LOFT_A, 0.08, 0.08), wood)   # korkuluk
	lever(196.0, LOFT_Y)
	mesh_box(loft, Vector3(196.0 - (LOFT_A + LOFT_B) * 0.5, 0.15, 0), Vector3(1.2, 0.05, 1.4), brass)

func _puzzle_kiler() -> void:
	sign_at(STATIONS[4], "5 · Karanlık kiler", 3.9)
	for i in LAMPS.size():
		var lx: float = LAMPS[i]
		prop("gaz_lambasi", Vector3(lx, 1.55, -0.9), 0.55, func(p: Node3D) -> void:
			mesh_box(p, Vector3(0, 0.22, 0), Vector3(0.22, 0.3, 0.22), iron)
			mesh_box(p, Vector3(0, 1.2, 0), Vector3(0.03, 1.7, 0.03), iron))
		plate(lx, 0.9)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.42)
		l.light_energy = 0.0
		l.omni_range = 11.0
		l.omni_attenuation = 1.3
		l.position = Vector3(lx, 1.7, 0.2)
		add_child(l)
		lamp_lights.append(l)
	plate(238.0)
	lever(238.0)
	plate(255.0)
	prop("el_carki", Vector3(255.4, 1.0, -0.7), 1.0, func(p: Node3D) -> void: _wheel(p, 0.42, 8, iron, 0.08), null, true)

func _build_exit() -> void:
	# kurdele: babanın işareti, mağaraya giden yolda
	var red := material(Color(0.55, 0.06, 0.05))
	mesh_box(deko(282.0), Vector3(282.0, 1.9, -1.95), Vector3(0.05, 0.6, 0.12), red)
	prop("magara_agzi", Vector3(END_X - 1.0, 0.0, -2.5), 6.5, func(p: Node3D) -> void:
		ProtoOrtam.rock(p, Vector3(-2.6, 0.5, 0), Vector3(3.0, 5.5, 3.5), 41)
		ProtoOrtam.rock(p, Vector3(2.8, 0.5, 0), Vector3(3.2, 6.0, 3.5), 42)
		ProtoOrtam.rock(p, Vector3(0, 4.6, 0), Vector3(7.5, 3.0, 3.6), 43)
		var hole := material(Color(0.004, 0.004, 0.005))
		hole.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hole.disable_fog = true
		mesh_box(p, Vector3(0, 1.9, 0.9), Vector3(3.0, 3.8, 0.1), hole))

# ------------------------------------------------------------------ arayüz
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
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

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
		_reset_puzzles()
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

func _reset_puzzles() -> void:
	hold0 = false
	gear_state = "mounted" if solved[1] else "floor"
	_place_gear()
	for i in LAMPS.size():
		lamp_lit[i] = solved[4]

func _place_gear() -> void:
	if gear == null: return
	if gear_state == "floor":
		gear.position = Vector3(116.0, 0.45, -0.5)
		gear.rotation = Vector3(0.9, 0, 0)
	elif gear_state == "mounted":
		gear.position = Vector3(100.05, 1.25, -1.2)
		gear.rotation = Vector3.ZERO

# ------------------------------------------------------------------ kurallar
func tunnel_at(x: float) -> bool:
	return x > 106.3 and x < 109.7

func lit_x(x: float) -> bool:   # Çınar burada ışıkta mı (Nehir'in feneri ya da yanan lamba)
	if x < DARK_A or x > DARK_B: return true
	if absf(x - player.position.x) < LIGHT_R: return true
	for i in LAMPS.size():
		if lamp_lit[i] and absf(x - float(LAMPS[i])) < LIGHT_R: return true
	return false

func door0_open() -> bool:
	return solved[0] or hold0

func saw_running() -> bool:
	return solved[1] and not solved[2] and not occupied(140, cinar)

func safe_target(from: float, target: float) -> float:
	var result := clampf(target, -5, END_X - 2.0)
	for i in GATES.size():
		if solved[i] or i == 1 or (i == 0 and door0_open()):
			continue
		if from < GATES[i] and result > GATES[i] - 0.8:
			result = GATES[i] - 0.8
	if not solved[2] and from < SAW_X and result > SAW_X - 1.6:
		result = SAW_X - 1.6
	# karanlık korkusu: ışığın dışına tek başına çıkmaz
	if result > DARK_A and not solved[4] and not lit_x(result):
		var step := 0.5 if result > from else -0.5
		var x := clampf(from, DARK_A - 0.5, DARK_B)
		var best := minf(from, DARK_A - 0.5) if step > 0 else from
		while (step > 0 and x < result) or (step < 0 and x > result):
			if not lit_x(x): break
			best = x
			x += step
		result = best
	return result

func send_to(x: float) -> void:
	var t := safe_target(cinar.position.x, x)
	if x > DARK_A and x < DARK_B and absf(t - x) > 0.6 and not solved[4]:
		hint.text = "Çınar karanlığa tek başına girmiyor. Işık gerek."
	cinar.command("go", t)
	selected = false

func occupied(x: float, who: Node3D, radius := 0.85) -> bool:
	return absf(who.position.x - x) < radius and absf(who.position.y) < 0.3

func companion_lever() -> bool:
	return (not solved[2] and occupied(140, cinar)) or (not solved[3] and occupied(WINCH_X, cinar)) or (not solved[4] and occupied(255, cinar))

func interact() -> void:
	if phase != "play": return
	var px := player.position.x
	if not solved[0] and occupied(56, player, 1.3):
		hold0 = true
		player.play_interaction("cooperate/LeverPull")
		audio.play("cark")
		hint.text = "Nehir çarkı tutuyor, kapı açık. Çınar'ı içerideki sarı mandala gönder."
	elif not solved[1] and occupied(100, player, 1.5):
		if gear_state == "carried" and absf(cinar.position.x - 100.0) < 3.0:
			player.play_interaction("cooperate/LeverPull")
			gear_state = "mounted"
			_place_gear()
			audio.play("cark")
			complete(1)
		else: hint.text = "Mil boş. Eksik dişli duvarın ötesinde; oraya yalnız Çınar sığar."
	elif not solved[2] and occupied(157, player, 1.5):
		player.play_interaction("cooperate/LeverPull")
		complete(2)
	elif not solved[3] and absf(px - 196.0) < 1.5 and player.position.y > LOFT_Y - 0.4:
		player.play_interaction("cooperate/LeverPull")
		complete(3)
	elif not solved[4] and (occupied(LAMPS[0], player, 1.2) or occupied(LAMPS[1], player, 1.2)):
		var i := 0 if absf(px - float(LAMPS[0])) < 1.2 else 1
		if not lamp_lit[i]:
			lamp_lit[i] = true
			player.play_interaction("cooperate/SymbolTouch", PI / 2.0)
			audio.play("kumas")
			hint.text = "Lamba yandı. Çınar ışığın olduğu yerde tek başına bekleyebilir."
	elif not solved[4] and occupied(238, player, 1.5):
		if occupied(255, cinar):
			player.play_interaction("cooperate/LeverPull")
			complete(4)
		else: hint.text = "Kol tek başına yetmiyor: ilerideki çarkı da biri tutmalı."

func complete(i: int) -> void:
	if solved[i]: return
	solved[i] = true
	checkpoint = i + 1
	audio.play("kapi_kalk", -8)
	hint.text = NAMES[i] + " tamamlandı. Çınar'ı takip etmeye çağır."
	if i == 4:
		for k in LAMPS.size(): lamp_lit[k] = true
	save_progress()

func current_station() -> int:
	for i in solved.size():
		if not solved[i]: return i
	return solved.size() - 1

func _hurt() -> void:   # testere: kısa kararma, son kontrol noktası
	if hurt_t > 0.0: return
	hurt_t = 0.9
	audio.play("yakalandi", -6)
	player.state = "cut"
	player.input_x = 0.0
	player.velocity = Vector3.ZERO

func _physics_process(dt: float) -> void:
	if lift == null or cinar == null or phase != "play": return
	var want := LOFT_Y - 0.1 if (not solved[3] and occupied(WINCH_X, cinar)) else -0.06
	if absf(player.position.x - LIFT_X) < 0.95 and player.position.y < lift_y + 0.5 and want < lift_y and solved[3]:
		want = lift_y
	lift_y = move_toward(lift_y, want, dt * (0.9 if want > lift_y else 1.6))
	lift.position.y = lift_y - 0.04

func _process(dt: float) -> void:
	if player == null or cinar == null: return
	var st := current_station()
	var wide: bool = not solved[st] and absf(player.position.x - STATIONS[st]) < 17.0
	var mid := player.position.x + 1.0
	if absf(cinar.position.x - player.position.x) < 10.0:
		mid = (player.position.x + cinar.position.x) * 0.5 + 0.5
	cam_dist = lerpf(cam_dist, 19.0 if wide else 14.0, 1.0 - exp(-dt * 1.2))
	cam.position = cam.position.lerp(Vector3(mid, maxf(player.position.y, 0.0) + 1.35 + (cam_dist - 14.0) * 0.12, cam_dist), 1.0 - exp(-dt * 2.4))
	cam.rotation = Vector3(deg_to_rad(0.5 - (cam_dist - 14.0) * 0.35), 0, 0)
	_gorunur(cam.position.x)
	_animate(dt)
	status.text = "DEĞİRMEN  ·  %d / 5  ·  Çınar: %s%s" % [solved.count(true), {"follow":"takip", "stay":"bekliyor", "go":"gidiyor"}[cinar.mode], "  ·  DURAKLATILDI" if paused else ""]
	target_marker.visible = phase == "play" and (selected or cinar.mode == "go")
	target_marker.position = Vector3(cinar.position.x if selected else cinar.target_x, 0.08, 0)
	if phase == "done":
		done_t += dt
		return
	if phase != "play": return
	elapsed += dt
	if hurt_t > 0.0:
		hurt_t -= dt
		fade.color.a = clampf(sin((0.9 - hurt_t) / 0.9 * PI) * 1.6, 0.0, 1.0)
		if hurt_t <= 0.45 and player.state == "cut":
			restore_checkpoint()
		if hurt_t <= 0.0: fade.color.a = 0.0
		return
	if st != shown_station and absf(player.position.x - STATIONS[st]) < 12:
		shown_station = st
		hint.text = INTRO[st]
	var axis := Input.get_action_strength("right") - Input.get_action_strength("left")
	if finger != null and touches.has(finger):
		var f: Dictionary = touches[finger]
		axis = clampf((f.pos.x - f.start.x) / 120.0, -1, 1)
	player.input_x = axis if bot_axis == null else float(bot_axis)
	player.grab_held = Input.is_action_pressed("grab")
	if Input.is_action_just_pressed("jump"): player.jump_pressed = true
	# 1: savak
	if hold0 and not occupied(56, player, 1.4):
		hold0 = false
		if not solved[0]: hint.text = "Çark bırakılınca kapı iniyor."
	if not solved[0] and hold0 and occupied(67, cinar): complete(0)
	if not solved[0] and not door0_open() and cinar.position.x > GATES[0] - 0.3:   # kapı kapanırken eşikte kalmasın
		cinar.position.x = GATES[0] + 0.9 if cinar.position.x > GATES[0] else cinar.position.x
	# 2: dişli
	if gear_state == "floor" and not solved[1] and absf(cinar.position.x - 116.0) < 0.6:
		gear_state = "carried"
		audio.play("kumas")
		hint.text = "Çınar dişliyi aldı. Onu geri çağır ve mile gelip Kullan'a bas."
	if gear_state == "carried":
		gear.position = cinar.position + Vector3(0.0, 0.62, 0.22)
		gear.rotation = Vector3.ZERO
	# 3: testere
	if saw_running() and absf(player.position.x - SAW_X) < 0.5 and player.position.y < 2.5:
		_hurt()
	# 5: karanlık
	if not solved[4] and cinar.mode == "stay" and not lit_x(cinar.position.x):
		cinar.command("follow")
		hint.text = "Çınar karanlıkta yalnız kalamıyor, ablasına koşuyor."
	if selected:
		hint.text = "Çınar seçili: gitmesini istediğin zemine veya sarı işarete dokun."
	elif player.position.x < 16:
		hint.text = "Derenin sesi yakın. Sisin içinde eski bir değirmen var."
	if player.position.x > END_X - 8.0 and cinar.position.x > END_X - 11.0 and solved.count(true) == 5:
		phase = "done"
		player.input_x = 0
		player.state = "cut"
		cinar.command("stay")
		hint.text = "Değirmeni birlikte geçtiniz. Kurdele mağarayı gösteriyor.  ·  Menü ile dön."
		save_progress()

func _gate_closed_y(i: int) -> float:
	return 0.7 if i == 3 else 1.75
func _gate_open_y(i: int) -> float:
	return -0.8 if i == 3 else 5.4   # 4. kapı yere gömülür

func _animate(dt: float) -> void:
	# kapılar yumuşak kalkar/iner
	for i in gates.size():
		var up: bool = solved[i] or (i == 0 and hold0)
		gate_y[i] = move_toward(gate_y[i], _gate_open_y(i) if up else _gate_closed_y(i), dt * (2.2 if up else 5.0))
		gates[i].position.y = gate_y[i]
	var flow := 1.0 if door0_open() else 0.0
	water_wheel.rotation.z -= dt * 0.55 * flow
	if hold0: sluice_wheel.rotation.z -= dt * 2.5
	# dişliler: büyük hep döner; küçük, eksik dişli takılınca
	gears[0].rotation.z += dt * 0.5 * flow
	if solved[1]:
		gears[1].rotation.z += dt * 0.92 * flow
		if gear_state == "mounted": gear.rotation.z -= dt * 1.28 * flow
	# testere
	if saw_running():
		saw_t += dt
		if absf(cam.position.x - SAW_X) < 14.0 and fmod(saw_t, 0.7) < dt:
			audio.play("kasa_surt", -14)
	saw.position.y = 1.75 + sin(saw_t * 9.0) * 0.55
	# karanlık kiler: ortam kararır, lambalar yanar
	var cx := cam.position.x
	var ic := smoothstep(56.0, 66.0, cx) * (1.0 - smoothstep(262.0, 270.0, cx))
	var kar := smoothstep(DARK_A - 8.0, DARK_A + 2.0, cx) * (1.0 - smoothstep(DARK_B, DARK_B + 6.0, cx))
	var k := maxf(ic * 0.6, kar)
	var c := ProtoOrtam.FOG.lerp(Color(0.012, 0.012, 0.016), k)
	env.background_color = c
	env.fog_light_color = c
	env.ambient_light_energy = lerpf(lerpf(0.3, 2.4, ic), 0.14, kar)
	env.fog_density = lerpf(1.0, 0.12, maxf(ic, kar))   # içeride sis incelir (koyu sis her şeyi yutmasın)
	sun.light_energy = lerpf(0.34, 0.0, kar)
	for i in lamp_lights.size():
		lamp_lights[i].light_energy = move_toward(lamp_lights[i].light_energy, 6.0 if lamp_lit[i] else 0.0, dt * 6.0)

# ------------------------------------------------------------------ girdi
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
	hold0 = false
	lift_y = -0.06
	if gear_state == "carried":
		gear_state = "floor"
	_place_gear()
	phase = "play"

func save_progress() -> void:
	if test_mode: return
	var config := ConfigFile.new()
	config.set_value("degirmen", "solved", solved)
	config.set_value("degirmen", "elapsed", elapsed)
	config.save("user://degirmen.cfg")

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load("user://degirmen.cfg") != OK: return
	var saved = config.get_value("degirmen", "solved", [])
	if not saved is Array or saved.size() != 5: return
	if saved.count(true) == 5: return   # bitmiş bölüm baştan açılır
	for i in 5:
		if saved[i] != true: break
		solved[i] = true
		checkpoint = i + 1
		gate_y[i] = _gate_open_y(i)
	_reset_puzzles()
	elapsed = float(config.get_value("degirmen", "elapsed", 0.0))
	restore_checkpoint()

# ------------------------------------------------------------------ NehirProto'nun sorduğu dünya bilgisi
func ground_y(x: float) -> float:
	if player != null and player.position.y > 1.0:
		if x > LOFT_A - 0.1 and x < LOFT_B + 1.2: return LOFT_Y   # çatı katı; ucundan aşağı atlanır
		if absf(x - LIFT_X) < 0.95: return lift_y
	return 0.0
func surface_at(p: Node3D) -> String:
	return "tahta" if p.position.x > 62.0 and p.position.x < 264.0 else "toprak"
func crate_at(_p: Node3D, _dir: int) -> Node: return null
func find_ledge(_p: NehirProto, _air: bool, _dir: float) -> Dictionary: return {}
func find_ledge_ground(_p: NehirProto) -> Dictionary: return {}

# ------------------------------------------------------------------ testler
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("DEGIRMEN HATA: ", message)

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func run_tests() -> void:
	await _wait(1.0)
	check(safe_target(50, 100) < GATES[0], "Kapalı değirmen kapısı Çınar'ı durdurmalı")
	player.position = Vector3(56, 0.08, 0)
	interact()
	await _wait(0.2)
	check(hold0 and not solved[0], "Çark tutulunca kapı açılmalı ama çözülmemeli")
	check(safe_target(50, 67) > 66.0, "Kapı açıkken Çınar içeri gidebilmeli")
	player.position.x = 50
	await _wait(0.2)
	check(not hold0, "Çarktan uzaklaşınca kapı bırakılmalı")
	player.position.x = 56
	interact()
	cinar.command("stay")
	cinar.position = Vector3(67, 0.08, 0)
	await _wait(0.2)
	check(solved[0], "Savak")
	player.position.x = 100
	interact()
	check(not solved[1], "Dişlisiz mil çözülmemeli")
	cinar.position.x = 116
	await _wait(0.2)
	check(gear_state == "carried", "Çınar dişliyi almalı")
	cinar.position.x = 101
	interact()
	check(solved[1] and gear_state == "mounted", "Kayıp dişli")
	check(tunnel_at(108.0) and not tunnel_at(112.0), "Alçak geçit aralığı")
	check(saw_running(), "Dişli takılınca testere çalışmalı")
	check(safe_target(140, 160) < SAW_X, "Testere Çınar'ı durdurmalı")
	cinar.position.x = 140
	await _wait(0.1)
	check(not saw_running(), "Debriyaj tutulunca testere durmalı")
	cinar.position.x = 130
	player.position.x = SAW_X
	await _wait(0.6)
	check(player.position.x < SAW_X - 5.0, "Çalışan testere Nehir'i kontrol noktasına döndürmeli")
	await _wait(0.6)
	player.position.x = 157
	interact()
	check(solved[2], "Testere")
	cinar.position.x = WINCH_X
	cinar.command("stay")
	player.position = Vector3(LIFT_X, 0.1, 0)
	await _wait(3.0)
	check(player.position.y > LOFT_Y - 0.3, "Asansör Nehir'i çatı katına çıkarmalı (y=%.2f)" % player.position.y)
	player.position = Vector3(196, LOFT_Y + 0.05, 0)
	await _wait(0.2)
	interact()
	check(solved[3], "Yük asansörü")
	player.position = Vector3(226, 0.08, 0)
	cinar.position.x = 224
	check(safe_target(224, 255) < 240.0, "Çınar karanlıkta ışıksız ilerlememeli")
	player.position.x = 230
	interact()
	player.position.x = 250
	interact()
	check(lamp_lit[0] and lamp_lit[1], "Lambalar yanmalı")
	check(absf(safe_target(250, 255) - 255.0) < 0.1, "Lamba ışığında Çınar çarka gidebilmeli")
	cinar.position.x = 255
	cinar.command("stay")
	player.position.x = 238
	await _wait(0.3)
	check(cinar.mode == "stay", "Işıkta Çınar beklemeli")
	interact()
	check(solved[4], "Karanlık kiler")
	player.position.x = END_X - 5.0
	cinar.position.x = END_X - 7.0
	await _wait(0.2)
	check(phase == "done", "Değirmen bitiş")
	action("restart")
	check(phase == "play" and solved.count(true) == 0 and gear_state == "floor", "Baştan temiz durum kurmalı")
	print("DEGIRMEN TEST hata=", failures)
	get_tree().quit(1 if failures else 0)

func walk_to(x: float) -> void:
	var seconds := 0.0
	while phase == "play" and absf(player.position.x - x) > 0.15 and seconds < 90.0:
		bot_axis = clampf((x - player.position.x) * 1.8, -1, 1)
		await _wait(0.05)
		seconds += 0.05
	bot_axis = 0.0
	check(seconds < 90, "Nehir hedefe ulaşamadı: %s (x=%.1f y=%.1f)" % [str(x), player.position.x, player.position.y])

func guide_to(x: float) -> void:
	send_to(x)
	var seconds := 0.0
	while absf(cinar.position.x - x) > 0.2 and seconds < 30:
		await _wait(0.05)
		seconds += 0.05
	check(seconds < 30, "Çınar hedefe ulaşamadı: %s (x=%.1f)" % [str(x), cinar.position.x])

## Gerçek fizik ve komutlarla baştan sona oynanış; ışınlama yok.
func run_walkthrough() -> void:
	Engine.time_scale = 6.0
	await _wait(1.0)
	await walk_to(56)
	interact()
	await guide_to(67)
	check(solved[0], "Oynanış: savak")
	cinar.command("stay")
	await walk_to(100)
	await guide_to(116)
	check(gear_state == "carried", "Oynanış: dişli alınmalı")
	cinar.command("follow")
	var bekle := 0.0
	while absf(cinar.position.x - 100.0) > 2.0 and bekle < 30.0:
		await _wait(0.1)
		bekle += 0.1
	interact()
	check(solved[1], "Oynanış: dişli")
	await walk_to(142)
	await guide_to(140)
	await walk_to(157)
	interact()
	check(solved[2], "Oynanış: testere")
	cinar.command("follow")
	await walk_to(LIFT_X)
	await guide_to(WINCH_X)
	await _wait(3.5)
	check(player.position.y > LOFT_Y - 0.3, "Oynanış: asansör yüksekliği y=%.2f" % player.position.y)
	await walk_to(196)
	interact()
	check(solved[3], "Oynanış: asansör")
	cinar.command("follow")
	await walk_to(204)
	await _wait(1.0)
	check(player.position.y < 0.3, "Oynanış: çatı katından inilmeli y=%.2f" % player.position.y)
	await walk_to(230)
	interact()
	await _wait(1.2)
	await walk_to(250)
	interact()
	await _wait(1.2)
	await guide_to(255)
	await walk_to(238)
	interact()
	check(solved[4], "Oynanış: kiler")
	cinar.command("follow")
	await walk_to(END_X - 6.0)
	await _wait(3.0)
	check(solved.count(true) == 5 and phase == "done", "Oynanış bitmeli")
	print("DEGIRMEN OYNANIS hata=", failures, " oyun_saniye=", elapsed)
	get_tree().quit(1 if failures else 0)

func run_shots() -> void:
	await _wait(1.5)
	var spots := [[8.0, 0], [54.0, 0], [66.0, 1], [100.0, 1], [112.0, 2], [148.0, 2], [184.0, 3], [196.0, 3], [226.0, 4], [248.0, 4], [272.0, 5], [294.0, 5]]
	for i in spots.size():
		var sx: float = spots[i][0]
		for k in solved.size(): solved[k] = k < int(spots[i][1])
		_reset_puzzles()
		if i == 9: lamp_lit = [true, true]
		hold0 = i == 1
		player.position = Vector3(sx, 0.1, 0)
		cinar.position = Vector3(sx - 1.3, 0.1, 0)
		if i == 7:
			player.position = Vector3(sx, LOFT_Y + 0.05, 0)
			cinar.position = Vector3(WINCH_X, 0.1, 0)
		cinar.command("stay")
		cam.position = Vector3(sx + 1, player.position.y + 1.35, 14)
		await _wait(3.0)
		get_viewport().get_texture().get_image().save_png("res://../degirmen_%02d.png" % i)
	get_tree().quit()
