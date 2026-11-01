extends Node3D
## ÖNSÖZ (oyun içi ara sahne, ~50 s, sessiz anlatım). Oyundaki modeller ve fenerle kurulur; dokununca atlanır.
## 1 Kış akşamı köy evi, pencerede lamba, sis ormandan geliyor.
## 2 Verandada Çınar; rüzgâr Pofuk'u elinden kapar, tavşan karda yuvarlanır.
## 3 Çınar tavşanın peşinden ormana koşar, sisin içinde kaybolur.
## 4 Nehir kapıda (arkasında annenin siluet), sise bakar, çividen feneri alır.
## 5 Nehir fenerle ormana yürür; annesi kapıda kalır.
## 6 Gece, derin orman: Nehir yamaçta kayar, düşer; fener yanına yuvarlanır. Kararır -> oyun (Nehir karda uyanır).
## Yerleşim: ev x 4..9, z -2..2 (kapı sol duvarda, x=4). Orman x < -3. Yamaç sahnesi x 95..140 (uzakta).

const FOG := Color(0.4, 0.44, 0.49)
const NAIL := Vector3(3.9, 1.55, 0.8)       # kapı yanındaki çivi: fener asılı
const SLIP_X := 109.7                        # yamaç kenarı (6. çekim)
var env: Environment
var sun: DirectionalLight3D
var cam: Camera3D
var cine: Cinematic
var shots: Array = []                        # [başla, bitir, konum0, bakış0, konum1, bakış1, fov]
var audio: ProtoAudio
var pl: NehirProto
var cinar: NehirMocap
var cinar_root: Node3D
var cinar_turn: Node3D
var cinar_to := Vector3.INF
var cinar_spd := 0.0
var pofuk: Node3D
var pof_half := 0.15
var pof_free := false
var pof_v := Vector3.ZERO
var pof_spin := 0.0
var wind := 0.0
var mother: NehirMocap
var snow: CPUParticles3D
var fade: ColorRect
var t := 0.0
var leaving := false
var test := ""
var _tex := {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="):
			test = a.substr(7)
	_rng.seed = 21
	_build_env()
	_build_ground()
	_build_house()
	_build_forest()
	_build_slope_scene()
	_build_snow()
	audio = ProtoAudio.new()
	add_child(audio)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.set_ambient(false)
	cam = Camera3D.new()
	cam.fov = 32.0
	cam.near = 0.05
	cam.far = 300.0
	add_child(cam)
	_build_people()
	var ui := CanvasLayer.new()
	add_child(ui)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)
	var skip := Label.new()
	skip.text = "geçmek için dokun"
	skip.add_theme_font_size_override("font_size", 16)
	skip.add_theme_color_override("font_color", Color(0.8, 0.8, 0.78, 0.35))
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.position = Vector2(-190, -40)
	skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(skip)
	_script()
	audio.start()
	audio.danger = 0.0
	if test != "":
		_run_test()

# ================================================================ dünya
func _build_env() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.58, 0.68)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 4.0
	env.fog_enabled = true
	env.fog_light_color = FOG
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 5.0
	env.fog_depth_end = 42.0
	env.fog_depth_curve = 0.6
	env.fog_density = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.78
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()   # alacakaranlık: soğuk, alçak, arkadan
	sun.light_color = Color(0.7, 0.78, 0.92)
	sun.light_energy = 0.28
	sun.rotation_degrees = Vector3(-22, 160, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)

func _mat(c: Color, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _noise_tex(freq: float) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = freq
	fn.fractal_octaves = 4
	nt.noise = fn
	nt.seamless = true
	return nt

func _box(size: Vector3, pos: Vector3, m: Material, solid := false, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		sb.position = pos
		sb.rotation = rot
		add_child(sb)
	return mi

func _snow_mat() -> StandardMaterial3D:
	var m := _mat(Color(0.74, 0.77, 0.82), 1.0)
	m.albedo_texture = _noise_tex(0.03)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.15, 0.15, 0.15)
	return m

## Zemin yüksekliği (fener fiziği ve oyuncu için): köy düzlüğü 0; yamaç sahnesinde düzlük, iniş, açıklık.
func ground_y(x: float) -> float:
	if x < 90.0 or x <= 110.0:
		return 0.0
	if x < 113.5:
		return lerpf(0.0, -2.2, (x - 110.0) / 3.5)
	return -2.2

func _build_ground() -> void:
	var sm := _snow_mat()
	_box(Vector3(120, 1.0, 80), Vector3(-10, -0.5, -20), sm, true)          # köy ve orman kenarı
	_box(Vector3(20, 1.0, 40), Vector3(100, -0.5, -10), sm, true)           # yamaç üstü (x 90..110)
	var ang := atan2(2.2, 3.5)
	var mid := Vector3(111.75, -1.1, 0)
	var nrm := Vector3(sin(ang), cos(ang), 0)
	_box(Vector3(4.15, 0.4, 40), mid - nrm * 0.2 + Vector3(0, 0, -10), sm, true, Vector3(0, 0, -ang))   # iniş
	_box(Vector3(30, 1.0, 40), Vector3(128.5, -2.7, -10), sm, true)         # açıklık (x 113.5..)

func _build_house() -> void:
	var wood := _mat(Color(0.11, 0.085, 0.07))
	wood.albedo_texture = _noise_tex(0.08)
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(0.3, 2.0, 0.3)
	var dark := _mat(Color(0.05, 0.045, 0.04))
	# duvarlar (kapı sol duvarda, ormana bakar)
	_box(Vector3(5.0, 2.5, 0.16), Vector3(6.5, 1.25, 2.0), wood, true)
	_box(Vector3(5.0, 2.5, 0.16), Vector3(6.5, 1.25, -2.0), wood, true)
	_box(Vector3(0.16, 2.5, 4.0), Vector3(9.0, 1.25, 0.0), wood, true)
	_box(Vector3(0.16, 2.5, 1.5), Vector3(4.0, 1.25, -1.25), wood, true)
	_box(Vector3(0.16, 2.5, 1.5), Vector3(4.0, 1.25, 1.25), wood, true)
	_box(Vector3(0.16, 0.5, 1.0), Vector3(4.0, 2.25, 0.0), wood)
	_box(Vector3(4.9, 0.05, 3.9), Vector3(6.5, 0.02, 0.0), dark)            # döşeme
	# çatı: sırtı x boyunca, üstünde kar
	for spec in [[Vector3(4.9, 1.5, 6.0), Vector3(6.5, 3.25, 0.0), dark], [Vector3(4.95, 1.42, 6.1), Vector3(6.5, 3.36, 0.0), _snow_mat()]]:
		var rf := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = spec[0]
		rf.mesh = pm
		rf.material_override = spec[2]
		rf.position = spec[1]
		rf.rotation.y = PI / 2.0
		add_child(rf)
	_box(Vector3(0.45, 1.4, 0.45), Vector3(7.8, 3.9, -0.8), dark)            # baca
	# açık kapı kanadı (dışa açılır)
	var hinge := Node3D.new()
	hinge.position = Vector3(3.95, 1.0, -0.5)
	hinge.rotation.y = 1.75   # içeri açılır (kameranın önünü kapatmasın)
	add_child(hinge)
	var leaf := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(0.06, 2.0, 0.98)
	leaf.mesh = lb
	leaf.material_override = wood
	leaf.position = Vector3(0, 0, 0.49)
	hinge.add_child(leaf)
	# pencere (ön duvar): sıcak lamba ışığı
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.62, 0.28)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.55, 0.22)
	glow.emission_energy_multiplier = 2.6
	glow.disable_fog = true
	_box(Vector3(0.75, 0.62, 0.02), Vector3(7.2, 1.5, 2.09), glow)
	_box(Vector3(0.05, 0.62, 0.04), Vector3(7.2, 1.5, 2.11), dark)
	_box(Vector3(0.75, 0.05, 0.04), Vector3(7.2, 1.5, 2.11), dark)
	_box(Vector3(0.9, 0.08, 0.12), Vector3(7.2, 1.15, 2.12), dark)
	var wl := OmniLight3D.new()
	wl.light_color = Color(1.0, 0.62, 0.3)
	wl.light_energy = 1.4
	wl.omni_range = 4.5
	wl.position = Vector3(7.2, 1.5, 2.8)
	add_child(wl)
	# içerisi: kapıdan dışarı taşan sıcak ışık
	var il := OmniLight3D.new()
	il.light_color = Color(1.0, 0.6, 0.28)
	il.light_energy = 2.2
	il.omni_range = 6.0
	il.position = Vector3(6.4, 1.7, 0.0)
	add_child(il)
	var back := _box(Vector3(0.05, 2.4, 3.8), Vector3(8.9, 1.2, 0.0), glow.duplicate())
	(back.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5
	# çivi
	_box(Vector3(0.12, 0.03, 0.03), NAIL + Vector3(-0.04, 0.06, 0), dark)
	# çit ve kütük (siluet sprite)
	_sprite("cit", Vector3(10.5, -0.05, 1.2), 1.1, 0.35)
	_sprite("cit", Vector3(12.6, -0.05, 1.0), 1.1, 0.35, true)
	_sprite("kutuk_kesik", Vector3(2.2, -0.02, -1.8), 0.6, 0.4)

func _tex_of(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://assets/cevre/%s.png" % n)
	return _tex[n]

func _sprite(n: String, pos: Vector3, h: float, dark := 1.0, flip := false) -> Sprite3D:
	var tx := _tex_of(n)
	var sp := Sprite3D.new()
	sp.texture = tx
	sp.pixel_size = h / float(tx.get_height())
	sp.offset = Vector2(0, tx.get_height() / 2.0)
	sp.position = pos
	sp.flip_h = flip
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sp.shaded = true
	sp.double_sided = true
	sp.modulate = Color(dark, dark, dark)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sp)
	return sp

func _trunk(pos: Vector3, r: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.62
	cm.bottom_radius = r
	cm.height = 22.0
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos + Vector3(0, 11.0, 0)
	mi.rotation.z = _rng.randf_range(-0.05, 0.05)
	add_child(mi)
	var root := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = r
	rm.bottom_radius = r * 1.7
	rm.height = 0.5
	rm.radial_segments = 12
	root.mesh = rm
	root.material_override = m
	root.position = pos + Vector3(0, 0.25, 0)
	add_child(root)

func _forest(x0: float, x1: float, z0: float, z1: float, step: float, m: Material, gy := 0.0) -> void:
	var x := x0
	while x < x1:
		x += _rng.randf_range(step * 0.6, step * 1.4)
		_trunk(Vector3(x, gy, _rng.randf_range(z0, z1)), _rng.randf_range(0.16, 0.34), m)

func _build_forest() -> void:
	var bark := _mat(Color(0.07, 0.065, 0.06))
	bark.albedo_texture = _noise_tex(0.05)
	bark.uv1_triplanar = true
	bark.uv1_scale = Vector3(0.8, 0.12, 0.8)
	_forest(-45.0, -3.0, -14.0, -1.5, 1.6, bark)      # orman kenarı: köyün solu
	_forest(-45.0, -6.0, 0.8, 3.0, 4.0, bark)
	_forest(1.0, 30.0, -16.0, -7.0, 3.5, bark)         # evin arkası, seyrek
	var names := ["agac_ince", "agac_kalin", "agac_kuru_cam", "agac_olu", "agac_cift", "agac_genc"]
	for layer in [[-14.0, -20.0, 3.0], [-20.0, -30.0, 4.0], [-30.0, -42.0, 5.5]]:
		var x := -50.0
		while x < 40.0:
			x += _rng.randf_range(float(layer[2]) * 0.6, float(layer[2]) * 1.4)
			_sprite(names[_rng.randi() % names.size()], Vector3(x, -0.3, _rng.randf_range(layer[1], layer[0])), _rng.randf_range(9.0, 15.0), 1.0, _rng.randf() < 0.5)
	# ön planda koyu gövdeler (derinlik)
	var black := _mat(Color(0.02, 0.02, 0.022))
	for fx in [-9.0, -15.0]:
		_trunk(Vector3(fx, 0.0, 4.5), 0.42, black)

func _build_slope_scene() -> void:
	var bark := _mat(Color(0.06, 0.055, 0.05))
	bark.albedo_texture = _noise_tex(0.05)
	bark.uv1_triplanar = true
	bark.uv1_scale = Vector3(0.8, 0.12, 0.8)
	_forest(92.0, 110.0, -9.0, -1.4, 1.5, bark, 0.0)
	_forest(113.5, 135.0, -9.0, -1.4, 1.7, bark, -2.2)
	_trunk(Vector3(106.6, 0.0, -1.0), 0.3, bark)       # kurdeleli ağaç
	var rib := StandardMaterial3D.new()               # babanın kurdelesi: soluk kırmızı, iki sarkan uç
	rib.albedo_color = Color(0.55, 0.06, 0.05)
	rib.roughness = 0.9
	_box(Vector3(0.64, 0.06, 0.64), Vector3(106.6, 1.65, -1.0), rib)
	_box(Vector3(0.05, 0.42, 0.02), Vector3(106.45, 1.42, -0.66), rib, false, Vector3(0, 0, 0.12))
	_box(Vector3(0.05, 0.36, 0.02), Vector3(106.56, 1.45, -0.66), rib, false, Vector3(0, 0, -0.08))
	var names := ["agac_ince", "agac_kalin", "agac_olu", "agac_genc"]
	var x := 85.0
	while x < 145.0:
		x += _rng.randf_range(2.0, 4.0)
		_sprite(names[_rng.randi() % names.size()], Vector3(x, -3.0, _rng.randf_range(-24.0, -12.0)), _rng.randf_range(10.0, 15.0), 0.8, _rng.randf() < 0.5)

func _build_snow() -> void:   # kameranın etrafında yağan kar; rüzgâr hamlesinde yana savrulur
	snow = CPUParticles3D.new()
	snow.amount = 500
	snow.lifetime = 7.0
	snow.preprocess = 7.0
	snow.local_coords = false
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(9, 0.5, 6)
	snow.direction = Vector3(0, -1, 0)
	snow.spread = 20.0
	snow.initial_velocity_min = 0.2
	snow.initial_velocity_max = 0.5
	snow.gravity = Vector3(0.05, -0.45, 0)
	snow.scale_amount_min = 0.5
	snow.scale_amount_max = 1.2
	var qm := QuadMesh.new()
	qm.size = Vector2(0.025, 0.025)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.92, 0.94, 0.98, 0.8)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.material = sm
	snow.mesh = qm
	add_child(snow)

# ================================================================ karakterler
func _build_people() -> void:
	# Nehir: oyuncu sınıfı (fener, ışık, animasyon hazır), kontrol tamamen sahnede
	pl = NehirProto.new()
	pl.world = self
	pl.position = Vector3(5.3, 0.05, 0.0)
	add_child(pl)
	pl.state = "cut"
	pl.face = -1
	pl.yaw = -PI
	pl.lamp_on = 0.55
	pl.lantern_ground = NAIL
	pl.lantern_upright = true
	pl.mocap.visible = false
	# Çınar: verandada, ormana dönük, Pofuk elinde
	cinar_root = Node3D.new()
	cinar_root.position = Vector3(3.2, 0.0, 0.05)
	add_child(cinar_root)
	cinar_turn = Node3D.new()
	cinar_turn.rotation.y = -PI
	cinar_root.add_child(cinar_turn)
	cinar = NehirMocap.new()
	cinar.who = "cinar"
	cinar.height = 1.15
	cinar_turn.add_child(cinar)
	if ResourceLoader.exists("res://proto/mocap/pofuk.glb"):
		pofuk = (load("res://proto/mocap/pofuk.glb") as PackedScene).instantiate()
		var bap := pofuk.find_child("AnimationPlayer", true, false)
		if bap != null:
			bap.queue_free()
		pofuk.top_level = true
		add_child(pofuk)
		var ab := AABB()
		var first := true
		for mi in pofuk.find_children("*", "MeshInstance3D", true, false):
			var bb: AABB = (mi as MeshInstance3D).get_aabb()
			ab = bb if first else ab.merge(bb)
			first = false
		pof_half = maxf(0.05, (ab.get_center().y - ab.position.y) * 0.2)
	# anne: içeride, ışığa karşı koyu siluet (yüzü görünmez)
	mother = NehirMocap.new()
	var mt := Node3D.new()
	mt.position = Vector3(5.6, 0.0, 0.1)
	mt.rotation.y = -PI
	mt.visible = false
	add_child(mt)
	mt.add_child(mother)
	mother.model.scale *= 1.17
	var sil := StandardMaterial3D.new()
	sil.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sil.albedo_color = Color(0.015, 0.013, 0.012)
	for mi in mother.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = sil

# ================================================================ senaryo
func _shot(t0: float, t1: float, p0: Vector3, l0: Vector3, p1: Vector3, l1: Vector3, fov := 32.0) -> void:
	shots.append([t0, t1, p0, l0, p1, l1, fov])

func _script() -> void:
	cine = Cinematic.new()
	var c := cine
	# 1 köy evi
	_shot(0.0, 7.0, Vector3(0.5, 3.4, 18.0), Vector3(3.0, 1.2, -2.0), Vector3(2.4, 2.3, 12.5), Vector3(3.8, 1.2, -1.0), 34.0)
	c.at(0.0, func() -> void: _fade_to(0.0, 2.5))
	# 2 veranda: rüzgâr Pofuk'u kapar
	_shot(7.0, 13.2, Vector3(1.7, 1.05, 4.8), Vector3(2.7, 0.75, 0.0), Vector3(1.4, 1.0, 4.5), Vector3(2.3, 0.7, 0.0), 30.0)
	c.at(9.6, _gust)
	c.at(9.75, func() -> void:   # tavşan elinden uçar
		pof_free = true
		pof_v = Vector3(-3.0, 1.9, 0.35)
		pof_spin = 9.0
		cinar.reach = 1.0
		audio.play("nefes_al", -10.0, 0.15))
	c.at(11.0, func() -> void: cinar.reach = 0.0)
	c.at(11.3, func() -> void: cinar_to = Vector3(-13.0, 0.0, -9.5))   # peşinden koşar
	# 3 orman kenarı: sise karışır
	_shot(13.2, 20.0, Vector3(-1.2, 1.5, 8.5), Vector3(-7.0, 0.9, -4.0), Vector3(-1.6, 1.45, 8.2), Vector3(-8.0, 0.9, -5.0), 32.0)
	c.at(17.5, func() -> void: _vanish(cinar, 2.0))
	c.at(17.0, func() -> void:
		if pofuk != null:
			_vanish(pofuk, 1.5))
	# 4 kapı: Nehir, arkasında anne; çividen feneri alır
	_shot(20.0, 28.6, Vector3(0.2, 1.4, 1.7), Vector3(4.1, 1.15, 0.2), Vector3(0.9, 1.35, 1.4), Vector3(4.1, 1.15, 0.2), 30.0)   # kapıya karşıdan
	c.at(20.0, func() -> void:
		pl.position = Vector3(4.3, 0.05, 0.0)   # eşikte, içerinin ışığı arkasında
		pl.mocap.visible = true
		pl.look_at = Vector3(-8.0, 1.2, -6.0)
		pl.mocap.set_any("M_Long_Breathe_and_Look_Around")
		pl.force_anim = "any"
		audio.play("nefes_ver", -12.0))
	c.at(21.2, func() -> void: (mother.get_parent() as Node3D).visible = true)
	c.at(24.0, func() -> void:   # fenere uzanır
		pl.force_anim = ""
		pl.look_at = NAIL
		create_tween().tween_property(pl, "reach", 1.0, 0.6))
	c.at(24.9, func() -> void:   # alır: önce sol elde, alevi canlanır
		pl.lantern_left = 1.0
		pl.lantern_pick = NAIL
		pl.lan_th = 0.0
		create_tween().tween_property(pl, "lantern_pick_w", 1.0, 0.2).from(0.0)
		pl.lantern_ground = Vector3.INF
		pl.lantern_upright = false
		audio.play("kumas", -12.0)
		create_tween().tween_property(pl, "reach", 0.0, 0.7)
		var tw := create_tween()
		for v in [0.8, 0.5, 1.0, 0.75, 1.0]:
			tw.tween_property(pl, "lamp_on", v, 0.14))
	c.at(26.2, func() -> void:
		pl.look_at = Vector3(-8.0, 1.0, -6.0)
		create_tween().tween_property(pl, "lantern_left", 0.0, 0.8))
	c.at(27.6, func() -> void:   # ormana yürür
		pl.look_at = Vector3.INF
		pl.cut_speed = 0.45
		pl.cut_target_x = -14.0)
	# 5 geniş: ormana yürüyüş, anne kapıda
	_shot(28.6, 37.0, Vector3(0.6, 1.7, 7.8), Vector3(1.0, 1.0, 0.0), Vector3(-1.4, 2.2, 11.5), Vector3(-2.2, 1.0, -1.0), 32.0)
	c.at(28.4, func() -> void: (mother.get_parent() as Node3D).position = Vector3(4.4, 0.0, 0.0))
	c.at(36.0, func() -> void: _fade_to(1.0, 1.0))
	# 6 gece, derin orman: kayar, düşer, fener yuvarlanır
	_shot(37.0, 43.4, Vector3(103.5, 1.5, 6.2), Vector3(105.5, 0.8, 0.0), Vector3(107.2, 1.4, 6.2), Vector3(109.2, 0.6, 0.0), 30.0)
	c.at(37.0, func() -> void:
		pl.position = Vector3(103.2, 0.05, 0.0)
		pl.velocity = Vector3.ZERO
		pl.face = 1
		pl.yaw = 0.0
		pl.cut_target_x = 112.0
		pl.cut_speed = 0.42
		(mother.get_parent() as Node3D).visible = false
		env.ambient_light_energy = 0.17
		sun.light_energy = 0.14
		env.fog_depth_begin = 3.0
		env.fog_depth_end = 30.0
		_fade_to(0.0, 1.2))
	_shot(43.4, 46.2, Vector3(108.6, 1.8, 7.0), Vector3(111.5, -0.6, 0.0), Vector3(110.5, 2.6, 8.5), Vector3(113.8, -1.8, 0.0), 32.0)
	_shot(46.2, 51.0, Vector3(110.5, 2.6, 8.5), Vector3(113.8, -1.8, 0.0), Vector3(116.6, 4.4, 9.5), Vector3(114.4, -2.2, 0.0), 34.0)
	c.at(49.4, func() -> void: _fade_to(1.0, 1.4))
	c.at(51.0, _finish)

func _gust() -> void:   # rüzgâr hamlesi: kar yana savrulur, ses
	audio.play("ruzgar", -2.0, 0.05)
	wind = 1.0
	var tw := create_tween()
	tw.tween_property(snow, "gravity", Vector3(-7.0, -0.6, 0), 0.5)
	tw.tween_interval(1.6)
	tw.tween_property(snow, "gravity", Vector3(-0.6, -0.45, 0), 1.5)
	tw.parallel().tween_property(self, "wind", 0.25, 2.0)

func _slip() -> void:   # yamaç kenarında ayağı kayar: yuvarlanarak açıklığa düşer, fener yanına yuvarlanır
	pl.set_physics_process(false)
	pl.velocity = Vector3.ZERO
	pl.mocap.set_any("M_falling_down")
	pl.force_anim = "any"
	pl.state = "cut"
	audio.play("nefes_al", -6.0, 0.05)
	audio.play("kumas", -8.0)
	pl.throw_lantern(Vector3(3.4, 1.5, 0.45))   # yanına düşsün
	var a := pl.position
	var tw := create_tween()
	tw.tween_property(pl, "position", Vector3(SLIP_X + 0.9, ground_y(SLIP_X + 0.9), 0.0), 0.45).from(a).set_ease(Tween.EASE_IN)
	tw.tween_property(pl, "position", Vector3(114.3, -2.2, 0.0), 0.75).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:   # yere çarpar ve yığılır, hareketsiz kalır
		audio.play("inis", -4.0)
		pl.force_anim = "death")
	var lw := create_tween()   # alev kısılır (oyun buradan başlar)
	lw.tween_interval(1.6)
	lw.tween_property(pl, "lamp_on", 0.25, 1.4)

func _vanish(n: Node, d: float) -> void:   # sisin içinde kaybolma
	for mi in n.find_children("*", "GeometryInstance3D", true, false):
		create_tween().tween_property(mi, "transparency", 1.0, d)

func _fade_to(a: float, d: float) -> void:
	create_tween().tween_property(fade, "color:a", a, d)

func _finish() -> void:
	if leaving:
		return
	leaving = true
	if test != "":
		return
	get_tree().change_scene_to_file("res://proto/proto.tscn")

func _input(ev: InputEvent) -> void:   # dokun / tuşa bas: önsözü geç
	if leaving or test != "":
		return
	if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed):
		leaving = true
		var tw := create_tween()
		tw.tween_property(fade, "color:a", 1.0, 0.5)
		tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://proto/proto.tscn"))

# ================================================================ her kare
func _process(dt: float) -> void:
	dt = minf(dt, 0.05 if test == "" else 0.1)
	t += dt
	if pl.state == "ground":   # yere değince oyuncu kodu "ground"a döner: önsöz boyunca kontrol sahnede
		pl.state = "cut"
	cine.step(dt)
	_camera()
	snow.global_position = cam.global_position + Vector3(0, 4.0, -4.0)
	if pl.is_physics_processing() and pl.position.x >= SLIP_X and pl.position.x < 120.0:
		_slip()
	_update_cinar(dt)
	_update_pofuk(dt)
	if mother != null and (mother.get_parent() as Node3D).visible:
		mother.drive("loco", 0.0, 1.0, dt)

func _camera() -> void:
	for s: Array in shots:
		if t >= float(s[0]) and t < float(s[1]):
			var k := (t - float(s[0])) / (float(s[1]) - float(s[0]))
			k = k * k * (3.0 - 2.0 * k)
			cam.position = (s[2] as Vector3).lerp(s[4], k) + Vector3(sin(t * 0.37) * 0.02, sin(t * 0.53) * 0.015, 0.0)
			cam.look_at((s[3] as Vector3).lerp(s[5], k), Vector3.UP)
			cam.fov = float(s[6])
			return

func _update_cinar(dt: float) -> void:
	var v := 0.0
	if cinar_to != Vector3.INF:
		var d := cinar_to - cinar_root.position
		d.y = 0.0
		if d.length() > 0.1:
			v = minf(2.4, cinar_spd + dt * 5.0)
			cinar_root.position += d.normalized() * v * dt
			var want := atan2(-d.z, d.x)
			cinar_turn.rotation.y = lerp_angle(cinar_turn.rotation.y, want, 1.0 - exp(-dt * 10.0))
	cinar_spd = v
	if pofuk != null:
		cinar.reach_target = pofuk.global_position
	cinar.drive("loco", cinar_spd, 1.0, dt)

func _update_pofuk(dt: float) -> void:
	if pofuk == null:
		return
	if not pof_free:   # Çınar'ın sol elinin altında, dik
		var hand := cinar.bone_world("hand.L")
		pofuk.global_transform = Transform3D(Basis(Vector3.UP, cinar_turn.rotation.y + PI / 2.0).scaled(Vector3.ONE * 0.2), hand + Vector3(0, -0.24, 0))
		return
	# rüzgârda uçar, karda seker ve yuvarlanır; rüzgâr onu orman kenarına kadar sürükler, orada takılır
	var p := pofuk.global_position
	if p.x < -11.5:   # orman kenarında bir köke takıldı
		pof_v = pof_v.lerp(Vector3.ZERO, 1.0 - exp(-dt * 3.0))
		pof_spin = lerpf(pof_spin, 0.0, 1.0 - exp(-dt * 3.0))
	else:
		pof_v.x += -4.0 * wind * dt
	pof_v.y -= 9.8 * dt
	pof_v.z = lerpf(pof_v.z, -0.25 * wind, 1.0 - exp(-dt * 2.0))
	pof_v.x = maxf(pof_v.x, -3.6)
	p += pof_v * dt
	var gy := ground_y(p.x) + pof_half
	if p.y < gy:
		p.y = gy
		if pof_v.y < -1.0:
			pof_v.y *= -0.35
			pof_v.x *= 0.7
		else:
			pof_v.y = 0.0
			pof_v.x = move_toward(pof_v.x, -1.6 * wind if p.x > -11.5 else 0.0, dt * 3.0)
		pof_spin = lerpf(pof_spin, pof_v.x * 3.0, 1.0 - exp(-dt * 4.0))
	var b := pofuk.global_transform.basis.orthonormalized().rotated(Vector3.BACK, pof_spin * dt)
	pofuk.global_transform = Transform3D(b.scaled(Vector3.ONE * 0.2), p)

# ================================================================ dünya arayüzü (oyuncu sınıfı için)
func crate_at(_p: Node3D, _dir: int) -> Node:
	return null

func find_ledge_ground(_p: Node) -> Dictionary:
	return {}

func find_ledge(_p: Node, _air: bool, _dir: float) -> Dictionary:
	return {}

func surface_at(_p: Node3D) -> String:
	return "kar"

# ================================================================ test: kareler
func _run_test() -> void:
	audio.muted = true
	if test == "dbg":   # görüntüsüz hızlı kontrol (headless)
		while t < 50.0:
			await get_tree().process_frame
			if absf(t - roundf(t)) < 0.026:
				print("DBG t=%.1f n=%s v=%s hedef=%.1f zemin=%s durum=%s c=%s p=%s" % [t, pl.position.snapped(Vector3.ONE * 0.01), pl.velocity.snapped(Vector3.ONE * 0.01), pl.cut_target_x, pl.is_on_floor(), pl.state, cinar_root.position.snapped(Vector3.ONE * 0.1), pofuk.global_position.snapped(Vector3.ONE * 0.1)])
		get_tree().quit()
		return
	var times := [3.0, 8.5, 10.2, 11.6, 14.5, 17.5, 21.5, 24.6, 25.6, 30.0, 34.0, 39.0, 42.8, 44.2, 46.0, 48.8]
	var k := 0
	for tt: float in times:
		while t < tt:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../onsoz_%02d.png" % k)
		print("ONSOZ t=%.1f nehir=%s cinar=%s pofuk=%s" % [t, pl.position.snapped(Vector3.ONE * 0.01), cinar_root.position.snapped(Vector3.ONE * 0.01), pofuk.global_position.snapped(Vector3.ONE * 0.01) if pofuk != null else Vector3.ZERO])
		k += 1
	get_tree().quit()
