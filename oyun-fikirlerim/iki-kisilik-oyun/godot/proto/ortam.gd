class_name ProtoOrtam extends RefCounted
## Ortak orman ortamı: Kurdele bölümünün (proto.gd) görünümünü başka sahnelere taşır.
## Sis ve ışık, zemin malzemesi, 3D ağaç gövdeleri, uzak siluet orman katmanları, otlar, kayalar.
## Yalnız görsel üretir; çarpışma eklemez. Kullanım: ProtoOrtam.env(sahne) ve ProtoOrtam.orman(sahne, x0, x1, bosluklar).

const FOG := Color(0.47, 0.5, 0.52)

static var _tex := {}
static var _rock_mat: StandardMaterial3D = null
static var _bark_mat: StandardMaterial3D = null

static func noise_tex(freq: float, size := 256) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = freq
	fn.fractal_octaves = 4
	nt.noise = fn
	nt.width = size
	nt.height = size
	nt.seamless = true
	return nt

## Sisli orman havası (proto.gd ile aynı değerler) + arkadan gelen soğuk ışık. [Environment, güneş] döner.
static func env(parent: Node, mobile := false) -> Array:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = FOG
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.6, 0.66)
	e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.tonemap_white = 4.0
	e.fog_enabled = true
	e.fog_light_color = FOG
	e.fog_light_energy = 1.0
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_depth_begin = 11.0
	e.fog_depth_end = 85.0
	e.fog_depth_curve = 0.55
	e.fog_density = 1.0
	e.fog_sky_affect = 1.0
	e.glow_enabled = not mobile
	e.glow_intensity = 0.7
	e.glow_strength = 1.0
	e.glow_bloom = 0.04
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.08
	e.adjustment_saturation = 0.8
	var we := WorldEnvironment.new()
	we.environment = e
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.78, 0.84, 0.92)
	sun.light_energy = 0.34
	sun.rotation_degrees = Vector3(-28, 170, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 18.0 if mobile else 30.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if mobile else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	parent.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.6, 0.66, 0.75)
	fill.light_energy = 0.18
	fill.rotation_degrees = Vector3(-20, -20, 0)
	parent.add_child(fill)
	return [e, sun]

## Zemin malzemesi (koyu toprak; sis ve ışıkla karlı görünür)
static func ground_mat() -> StandardMaterial3D:
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.06, 0.052, 0.045)
	gm.roughness = 0.95
	gm.albedo_texture = noise_tex(0.03)
	gm.uv1_triplanar = true
	gm.uv1_scale = Vector3(0.35, 0.35, 0.35)
	return gm

static func stone_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.13, 0.13, 0.14)
	m.roughness = 1.0
	m.albedo_texture = noise_tex(0.2)
	m.uv1_triplanar = true
	return m

static func wood_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.09, 0.07)
	m.roughness = 0.95
	m.albedo_texture = noise_tex(0.09)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.4, 2.5, 0.4)
	return m

static func bark_mat() -> StandardMaterial3D:
	if _bark_mat == null:
		_bark_mat = StandardMaterial3D.new()
		_bark_mat.albedo_color = Color(0.075, 0.068, 0.062)
		_bark_mat.roughness = 0.95
		_bark_mat.albedo_texture = noise_tex(0.05)
		_bark_mat.uv1_triplanar = true
		_bark_mat.uv1_scale = Vector3(0.8, 0.12, 0.8)
	return _bark_mat

static func tex_of(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://assets/cevre/%s.png" % n)
	return _tex[n]

static func sprite(parent: Node, n: String, pos: Vector3, h: float, dark := 1.0, flip := false) -> Sprite3D:
	var tx := tex_of(n)
	var sp := Sprite3D.new()
	sp.texture = tx
	sp.pixel_size = h / float(tx.get_height())
	sp.offset = Vector2(0, tx.get_height() / 2.0)
	sp.position = pos
	sp.flip_h = flip
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.shaded = true
	sp.double_sided = true
	sp.modulate = Color(dark, dark, dark)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sp)
	return sp

## Gerçek 3D gövde: kök yayılması ve bir iki dal
static func trunk(parent: Node, pos: Vector3, r: float, rng: RandomNumberGenerator, m: Material = null, shadow := true) -> void:
	if m == null:
		m = bark_mat()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.62
	cm.bottom_radius = r
	cm.height = 22.0
	cm.radial_segments = 12
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos + Vector3(0, 11.0, 0)
	mi.rotation.z = rng.randf_range(-0.05, 0.05)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var root := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = r
	rm.bottom_radius = r * 1.7
	rm.height = 0.6
	rm.radial_segments = 12
	root.mesh = rm
	root.material_override = m
	root.position = pos + Vector3(0, 0.3, 0)
	parent.add_child(root)
	for k in rng.randi_range(0, 2):
		var br := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.015
		bm.bottom_radius = r * 0.3
		bm.height = rng.randf_range(1.5, 3.0)
		bm.radial_segments = 6
		br.mesh = bm
		br.material_override = m
		br.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		br.position = pos + Vector3(side * bm.height * 0.35, rng.randf_range(3.5, 7.5), 0)
		br.rotation.z = -side * rng.randf_range(0.7, 1.2)
		parent.add_child(br)

## Düzensiz kaya bloğu (üstü karlı). Görsel; çarpışmasız.
static func rock(parent: Node, pos: Vector3, size: Vector3, seed: int, snow := true) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 14
	sm.rings = 8
	var fn := FastNoiseLite.new()
	fn.seed = seed
	fn.frequency = 1.6
	var arr := sm.get_mesh_arrays()
	var mi := MeshInstance3D.new()
	if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:   # görüntüsüz (headless) çalışmada ağ verisi yok
		parent.add_child(mi)
		return mi
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var moved := PackedVector3Array()
	for v in vs:
		var d := 1.0 + fn.get_noise_3dv(v * 2.0) * 0.45
		var w := Vector3(v.x * d, v.y * d, v.z * d)
		w.y = maxf(w.y, -0.25) if w.y < 0.0 else w.y * 0.8
		moved.append(w * size)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		var w := moved[i]
		var up := clampf((w.y / maxf(size.y, 0.01) - 0.12) * 4.0, 0.0, 1.0) if snow else 0.0
		st.set_color(Color(0.07, 0.065, 0.06).lerp(Color(0.62, 0.65, 0.7), up))
		st.add_vertex(w)
	st.generate_normals()
	mi.mesh = st.commit()
	if _rock_mat == null:
		_rock_mat = StandardMaterial3D.new()
		_rock_mat.roughness = 0.95
		_rock_mat.vertex_color_use_as_albedo = true
		_rock_mat.albedo_texture = noise_tex(0.08)
		_rock_mat.uv1_triplanar = true
		_rock_mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	mi.material_override = _rock_mat
	mi.position = pos
	mi.rotation.y = float(seed % 7) * 0.9
	parent.add_child(mi)
	return mi

## x0..x1 arasını ormanla döşer. bosluklar: [[xa, xb], ...] içinde gövde/ot/kaya konmaz (uçurum, köprü).
## yol_bos: yol üstünde (|z| küçük) nesne bırakılmayan x aralıkları için de bosluklar kullanılabilir.
## on_bos: ön plandaki kalın gövdelerin konmayacağı aralıklar (bulmaca durakları kapanmasın).
static func orman(parent: Node, x0: float, x1: float, bosluklar := [], gy := 0.0, seed := 5, mobile := false, on_bos := []) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var in_gap := func(x: float) -> bool:
		for g: Array in bosluklar:
			if x > float(g[0]) and x < float(g[1]):
				return true
		return false
	# yakın arka: gerçek gövdeler (fener ışığını alır)
	var x := x0
	while x < x1:
		x += rng.randf_range(2.4, 5.2)
		if in_gap.call(x):
			continue
		trunk(parent, Vector3(x, gy - 0.2, rng.randf_range(-5.2, -1.9)), rng.randf_range(0.17, 0.36), rng)
	# ön plan: kameraya yakın koyu kalın gövdeler (seyrek)
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.02, 0.02, 0.022)
	x = x0 + 12.0
	while x < x1:
		var blocked: bool = in_gap.call(x)
		for g: Array in on_bos:
			if x > float(g[0]) and x < float(g[1]):
				blocked = true
		if not blocked:
			trunk(parent, Vector3(x, gy - 0.5, rng.randf_range(3.6, 5.2)), rng.randf_range(0.35, 0.5), rng, black, false)
		x += rng.randf_range(34.0, 52.0)
	# uzak katmanlar: siluet ağaçlar (sise gömülür)
	var names := ["agac_ince", "agac_kalin", "agac_kuru_cam", "agac_olu", "agac_cift", "agac_genc"]
	for layer in [[-7.0, -11.0, 3.2], [-12.0, -18.0, 4.0], [-19.0, -28.0, 5.0], [-29.0, -40.0, 6.5]]:
		x = x0 - 8.0
		while x < x1 + 8.0:
			x += rng.randf_range(float(layer[2]) * 0.6, float(layer[2]) * 1.4)
			sprite(parent, names[rng.randi() % names.size()], Vector3(x, gy - 0.3, rng.randf_range(layer[1], layer[0])), rng.randf_range(9.0, 15.0), 1.0, rng.randf() < 0.5)
	# otlar, çalılar (yolun üstü açık kalır)
	var kinds := [["ot", 0.55], ["cimen_oku", 0.3], ["egrelti", 0.5], ["cali", 0.6], ["dikenli_cali", 0.7], ["ot", 0.75], ["cicek", 0.45], ["mantar", 0.18]]
	x = x0
	var step := 0.9 if mobile else 0.55
	while x < x1:
		x += rng.randf_range(step * 0.4, step * 1.6)
		if in_gap.call(x):
			continue
		var z := rng.randf_range(-6.0, 3.2)
		if absf(z) < 0.95:
			z = -1.1 - rng.randf() * 0.6 if rng.randf() < 0.6 else 1.1 + rng.randf() * 0.6
		var k: Array = kinds[rng.randi() % kinds.size()]
		var h: float = float(k[1]) * rng.randf_range(0.7, 1.4) * (1.25 if z > 1.5 else 1.0)
		sprite(parent, k[0], Vector3(x, gy - 0.04, z), h, 1.0, rng.randf() < 0.5)
	# karlı kayalar (arka planda, seyrek)
	x = x0
	var n := 0
	while x < x1:
		x += rng.randf_range(7.0, 16.0)
		if in_gap.call(x):
			continue
		n += 1
		rock(parent, Vector3(x, gy - 0.15, rng.randf_range(-4.5, -2.0)), Vector3(rng.randf_range(0.8, 1.7), rng.randf_range(0.5, 1.0), rng.randf_range(0.7, 1.3)), seed * 100 + n)
