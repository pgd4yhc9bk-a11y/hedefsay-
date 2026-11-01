extends Node3D
## PROTOTİP BÖLÜM — "Kurdele" (Inside tarzı 2.5D)
## Nehir sisli ormanda tek başına uyanır; feneriyle ilerler, devrik kütüğü aşar, uçurumdan atlar,
## kasayı iterek yüksek kayaya tırmanır ve babasının bağladığı ilk kırmızı kurdeleyi bulur.
## Her şey kodla kurulur: zemin, ağaç katmanları, sis, ışık huzmeleri, toz, kamera, son sahne.

const FOG := Color(0.47, 0.5, 0.52)
const Z0 := -42.0
const Z1 := 12.0
# zemin profili (x, y): soldan sağa üst çizgi; dikey parçalar uçurum ve duvardır
const PROFILE := [
	Vector2(-16, 0.4), Vector2(-8, 0.05), Vector2(0, 0.0), Vector2(4, 0.12), Vector2(8, 0.0), Vector2(12, 0.22), Vector2(16, 0.32),
	Vector2(19, 0.18), Vector2(23, 0.1), Vector2(26, -0.15), Vector2(29, -0.42), Vector2(32.6, -0.5),
	Vector2(32.6, -16.0), Vector2(33.9, -16.0), Vector2(33.9, -0.55),
	Vector2(37, -0.5), Vector2(41, -0.45), Vector2(46.5, -0.5),
	Vector2(46.5, 1.6), Vector2(50, 1.7), Vector2(54, 1.9), Vector2(58, 2.05), Vector2(63, 2.0), Vector2(66, 1.95), Vector2(68, 1.85),
	Vector2(68, -30.0), Vector2(160, -30.0),
]
const LOG_X := 21.0
const LOG_R := 0.3
const CRATE_X := 40.0
const RIBBON_X := 62.4
const CHECKPOINTS := [Vector2(1.0, 0.0), Vector2(36.0, -0.5), Vector2(48.5, 1.65)]

var player: NehirProto
var cam: Camera3D
var crate: ProtoCrate
var ledges: Array = []           # {p: Vector3, dir: int, low: bool}
var env: Environment
var sun: DirectionalLight3D
var fade: ColorRect
var hint: Label
var title: Label
var sub: Label
var post: ShaderMaterial
var sisli: Sprite3D
var sisli_tex: Array = []
var sisli_a := 0.0
var sisli_gone := false
var ribbon_pts: Array = []
var ribbon_meshes: Array = []
var dust: CPUParticles3D
var leaves: CPUParticles3D
var cp := 0
var cam_pos := Vector3.ZERO
var cam_dist := 13.5
var look := 0.0
var t := 0.0
var phase := "intro"            # intro | play | dead | end | done
var end_t := 0.0
var dead_t := 0.0
var hint_t := 0.0
var test := ""
var close_cam := 0.0
var bot := {}
var _touch := {}                 # parmak indeksi -> {start, pos, t}
var _first := -1
var _jumped_swipe := false
var _grab_fingers := 0
var _tex := {}
var audio: ProtoAudio
var veg: Array = []              # rüzgârda sallanan bitkiler [sprite, faz]
var chaser: Sprite3D
var chase_tex: Array = []
var chase := "off"               # off | rise | run | stop | done
var chase_t := 0.0
var chase_x := 0.0
var caught := false
var music_on := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="):
			test = a.substr(7)
	_build_env()
	_build_terrain()
	_build_log()
	_build_vegetation()
	_build_trees()
	_build_sky()
	_build_fx()
	_build_sisli()
	_build_ribbon()
	_build_valley()
	_build_chaser()
	audio = ProtoAudio.new()
	add_child(audio)
	Sfx.set_ambient(false)
	crate = ProtoCrate.new()
	crate.position = Vector3(CRATE_X, -0.45, 0)
	crate.min_x = 37.6
	add_child(crate)
	player = NehirProto.new()
	player.world = self
	player.position = Vector3(CHECKPOINTS[0].x, CHECKPOINTS[0].y + 0.05, 0)
	player.died.connect(_on_died)
	add_child(player)
	_static_ledges()
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 0.1
	cam.far = 400.0
	add_child(cam)
	cam_pos = Vector3(player.position.x + 1.0, player.position.y + 1.3, cam_dist)
	cam.position = cam_pos
	_build_ui()
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_low_quality()
	if test == "":
		audio.start()
		player.wake_t = 2.8   # açılış: yerde yatarken uyanır
	else:
		audio.muted = true
		_run_test()

# ================================================================ dünya
func ground_y(x: float) -> float:
	for i in range(PROFILE.size() - 1):
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[i + 1]
		if a.x == b.x:
			continue
		if x >= a.x and x <= b.x:
			var y := _seg_y(a, b, x)
			if x == b.x and i + 1 < PROFILE.size() - 1 and PROFILE[i + 1].x == PROFILE[i + 2].x:
				return maxf(y, PROFILE[i + 2].y)   # tam kenarda: yüksek olan taraf
			return y
	return PROFILE[PROFILE.size() - 1].y

func _seg_y(a: Vector2, b: Vector2, x: float) -> float:
	var u := clampf((x - a.x) / (b.x - a.x), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u) * 0.5 + u * 0.5   # yumuşak eğim
	return lerpf(a.y, b.y, u)

func _breaks() -> Array:
	var out := []
	for i in range(PROFILE.size() - 1):
		if PROFILE[i].x == PROFILE[i + 1].x:
			out.append(PROFILE[i].x)
	return out

var _noise := FastNoiseLite.new()

func _bump(x: float, z: float, brk: Array) -> float:
	var az := absf(z)
	if az < 0.7:
		return 0.0
	var e := 1.0
	for bx: float in brk:
		e = minf(e, clampf((absf(x - bx) - 0.15) / 1.2, 0.0, 1.0))
	var k := smoothstep(0.7, 4.0, az)
	return (_noise.get_noise_2d(x * 2.0, z * 2.0) * 0.35 + _noise.get_noise_2d(x * 0.4, z * 0.4) * 0.9 * smoothstep(6.0, 20.0, az)) * k * e

func _build_env() -> void:
	_noise.seed = 7
	_noise.frequency = 0.08
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.66)
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 4.0
	env.fog_enabled = true
	env.fog_light_color = FOG
	env.fog_light_energy = 1.0
	env.fog_mode = Environment.FOG_MODE_DEPTH   # yakın plan net, uzak katmanlar sise gömülür
	env.fog_depth_begin = 9.0
	env.fog_depth_end = 75.0
	env.fog_depth_curve = 0.55
	env.fog_density = 1.0
	env.fog_sky_affect = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# bulutlu gökten gelen soğuk, yumuşak ışık (arkadan-yukarıdan: siluetlere kenar ışığı)
	sun = DirectionalLight3D.new()
	sun.light_color = Color(0.78, 0.84, 0.92)
	sun.light_energy = 0.34
	sun.rotation_degrees = Vector3(-28, 170, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 30.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.6, 0.66, 0.75)
	fill.light_energy = 0.18
	fill.rotation_degrees = Vector3(-20, -20, 0)
	add_child(fill)

func _mat(c: Color, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _noise_tex(freq: float, size := 256) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = freq
	fn.fractal_octaves = 4
	nt.noise = fn
	nt.width = size
	nt.height = size
	nt.seamless = true
	return nt

const PLAT_A := 46.5
const PLAT_B := 68.0
const ZF := 1.2          # yüksek kayanın kameraya bakan ön yüzü (önünde alçak patika devam eder)
const YF := -0.5

func _plat(x: float) -> bool:
	return x > PLAT_A - 0.001 and x < PLAT_B + 0.001

## Görsel zemin yüksekliği (tümsekler dahil): bitki ve ağaç yerleştirmek için
var _brk_cache: Array = []

func gy_at(x: float, z: float, base := NAN) -> float:
	if _brk_cache.is_empty():
		_brk_cache = _breaks()
	var brk := _brk_cache
	if _plat(x) and z > ZF:
		return YF + _bump(x, z, brk) * clampf((z - ZF) / 1.0, 0.0, 1.0)
	var b := _bump(x, z, brk)
	if _plat(x):
		b *= clampf((ZF - z) / 1.0, 0.0, 1.0)
	return (ground_y(x) if is_nan(base) else base) + b

func _build_terrain() -> void:
	var brk := _breaks()
	var zs := [Z0, -30.0, -22.0, -16.0, -11.0, -7.5, -5.0, -3.2, -2.0, -1.2, -0.7, 0.0, 0.7, ZF, 2.4, 3.8, 5.5, 8.0, Z1]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in range(PROFILE.size() - 1):
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[i + 1]
		if a.x == b.x:   # dikey duvar (uçurum / kaya)
			var top := maxf(a.y, b.y)
			var bot := minf(a.y, b.y)
			var nx := 1.0 if b.y < a.y else -1.0
			for zi in range(zs.size() - 1):
				var z0: float = zs[zi]
				var z1: float = zs[zi + 1]
				var tp := top
				if z0 >= ZF - 0.001 and (absf(a.x - PLAT_A) < 0.01 or absf(a.x - PLAT_B) < 0.01):
					if absf(a.x - PLAT_A) < 0.01:
						continue          # kayanın önünde patika kesintisiz
					tp = YF               # son uçurum: patika da aşağı düşer
				_quad(st, Vector3(a.x, tp, z0), Vector3(a.x, tp, z1), Vector3(a.x, bot, z1), Vector3(a.x, bot, z0), nx > 0.0)
			faces.append_array([Vector3(a.x, top, -1.5), Vector3(a.x, top, 1.0), Vector3(a.x, bot, 1.0), Vector3(a.x, top, -1.5), Vector3(a.x, bot, 1.0), Vector3(a.x, bot, -1.5)])
			continue
		var n := maxi(1, int(ceil((b.x - a.x) / 0.5)))
		var last := i == PROFILE.size() - 2
		for k in n:
			var x0 := lerpf(a.x, b.x, float(k) / n)
			var x1 := lerpf(a.x, b.x, float(k + 1) / n)
			var y0 := a.y if last else _seg_y(a, b, x0)
			var y1 := b.y if last else _seg_y(a, b, x1)
			var plat := not last and _plat(x0) and _plat(x1)
			for zi in range(zs.size() - 1):
				var z0: float = zs[zi]
				var z1: float = zs[zi + 1]
				var q0: Vector3
				var q1: Vector3
				var q2: Vector3
				var q3: Vector3
				if last:
					q0 = Vector3(x0, y0, z0)
					q1 = Vector3(x1, y1, z0)
					q2 = Vector3(x1, y1, z1)
					q3 = Vector3(x0, y0, z1)
				else:
					q0 = Vector3(x0, gy_at(x0, z0, y0), z0)
					q1 = Vector3(x1, gy_at(x1, z0, y1), z0)
					q2 = Vector3(x1, gy_at(x1, z1, y1), z1)
					q3 = Vector3(x0, gy_at(x0, z1, y0), z1)
					if plat and absf(z0 - ZF) < 0.001:   # ön patikanın ilk sırası: kaya yüzüyle aynı hizada başlasın
						q0.y = YF
						q1.y = YF
					if plat and absf(z1 - ZF) < 0.001:
						q2.y = y1
						q3.y = y0
				_quad(st, q0, q1, q2, q3, true)
			if plat:   # kayanın kameraya bakan ön yüzü
				_quad(st, Vector3(x0, y0, ZF), Vector3(x1, y1, ZF), Vector3(x1, YF, ZF), Vector3(x0, YF, ZF), true)
			faces.append_array([Vector3(x0, y0, -1.5), Vector3(x1, y1, -1.5), Vector3(x1, y1, 1.0), Vector3(x0, y0, -1.5), Vector3(x1, y1, 1.0), Vector3(x0, y0, 1.0)])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var gm := _mat(Color(0.06, 0.052, 0.045))
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.albedo_texture = _noise_tex(0.03)
	gm.uv1_triplanar = true
	gm.uv1_scale = Vector3(0.35, 0.35, 0.35)
	mi.material_override = gm
	add_child(mi)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var cc := ConcavePolygonShape3D.new()
	cc.backface_collision = true
	cc.set_faces(faces)
	cs.shape = cc
	sb.add_child(cs)
	add_child(sb)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, up: bool) -> void:
	if up:
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
	else:
		for v in [a, c, b, a, d, c]:
			st.add_vertex(v)

func _build_log() -> void:   # devrik kütük: z boyunca uzanan silindir
	var y := ground_y(LOG_X) + LOG_R - 0.04
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = LOG_R
	cm.bottom_radius = LOG_R * 1.08
	cm.height = 7.0
	cm.radial_segments = 18
	mi.mesh = cm
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.position = Vector3(LOG_X, y, -1.6)
	var bark := _mat(Color(0.1, 0.085, 0.07))
	bark.albedo_texture = _noise_tex(0.06)
	bark.uv1_triplanar = true
	bark.uv1_scale = Vector3(0.6, 0.15, 0.6)
	mi.material_override = bark
	add_child(mi)
	for k in 3:   # kırık dallar
		var br := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.02
		bm.bottom_radius = 0.06
		bm.height = 0.7 + k * 0.2
		br.mesh = bm
		br.material_override = bark
		br.position = Vector3(LOG_X + (k - 1) * 0.12, y + 0.35, -0.6 - k * 1.4)
		br.rotation_degrees = Vector3(10 * k, 0, -35 + k * 30)
		add_child(br)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = LOG_R
	cyl.height = 4.0
	cs.shape = cyl
	cs.rotation_degrees = Vector3(90, 0, 0)
	cs.position = Vector3(LOG_X, y, 0)
	sb.add_child(cs)
	add_child(sb)

func _static_ledges() -> void:
	var ly := ground_y(LOG_X) + LOG_R * 2.0 - 0.06
	ledges = [
		{"p": Vector3(LOG_X - LOG_R * 0.75, ly, 0), "dir": 1, "low": true, "cap": 1.1},
		{"p": Vector3(LOG_X + LOG_R * 0.75, ly, 0), "dir": -1, "low": true, "cap": 1.1},
		{"p": Vector3(33.9, -0.55, 0), "dir": 1, "low": false},
		{"p": Vector3(32.6, -0.5, 0), "dir": -1, "low": false},
		{"p": Vector3(46.5, 1.6, 0), "dir": 1, "low": false},
	]

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
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.shaded = true
	sp.double_sided = true
	sp.modulate = Color(dark, dark, dark)
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sp)
	return sp

func _in_gap(x: float) -> bool:
	return (x > 32.3 and x < 34.7) or (x > 46.2 and x < 46.8) or x > 67.6

func _build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var brk := _breaks()
	var kinds := [["ot", 0.55], ["cimen_oku", 0.3], ["egrelti", 0.5], ["cali", 0.6], ["dikenli_cali", 0.7], ["ot", 0.75], ["cicek", 0.45], ["mantar", 0.18]]
	var x := -14.0
	while x < 70.0:
		x += rng.randf_range(0.15, 0.55)
		if _in_gap(x):
			continue
		var z := rng.randf_range(-6.0, 3.2)
		if absf(z) < 0.55 and rng.randf() < 0.75:
			z = -0.9 if z < 0.0 else 0.9          # yolun üstü biraz açık kalsın
		var k: Array = kinds[rng.randi() % kinds.size()]
		var h: float = float(k[1]) * rng.randf_range(0.7, 1.4) * (1.25 if z > 1.5 else 1.0)
		var vs := _sprite(k[0], Vector3(x, gy_at(x, z) - 0.04, z), h, 1.0, rng.randf() < 0.5)
		if z > -3.5:
			veg.append([vs, rng.randf() * TAU])
	# yüksek kayanın ön yüzüne sarkan kökler, sarmaşıklar ve kenar otları
	var hx := PLAT_A + 0.4
	while hx < PLAT_B - 0.5:
		var nm: String = ["kok_sarkit", "sarmasik", "dal_sarkit"][rng.randi() % 3]
		var tx := _tex_of(nm)
		var sp := Sprite3D.new()
		sp.texture = tx
		var hh := rng.randf_range(1.2, 2.6)
		sp.pixel_size = hh / float(tx.get_height())
		sp.offset = Vector2(0, -tx.get_height() / 2.0)
		sp.position = Vector3(hx, ground_y(hx) + 0.05, ZF + 0.03)
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sp.flip_h = rng.randf() < 0.5
		sp.modulate = Color(0.13, 0.13, 0.14)
		sp.shaded = false
		add_child(sp)
		_sprite("ot", Vector3(hx + 0.6, ground_y(hx + 0.6) - 0.03, ZF - 0.05), rng.randf_range(0.4, 0.7), 1.0, rng.randf() < 0.5)
		hx += rng.randf_range(2.4, 4.5)
	# kayalar ve kütükler
	for spec in [["kaya_orta", 6.5, -1.6, 0.8], ["tas_yigin", 13.5, 1.6, 0.6], ["kaya_buyuk", 27.0, -3.0, 1.6], ["kutuk_kesik", 10.0, -2.4, 0.7],
			["kaya_catlak", 43.0, -2.5, 1.3], ["kok_yigin", 37.5, 1.5, 0.7], ["kaya_orta", 52.5, -1.8, 0.9], ["tas", 56.0, 1.2, 0.35], ["kutuk_devrik", 59.0, -3.5, 0.9]]:
		var sx: float = spec[1]
		var sz: float = spec[2]
		_sprite(spec[0], Vector3(sx, gy_at(sx, sz) - 0.05, sz), spec[3])

func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var brk := _breaks()
	var bark := _mat(Color(0.075, 0.068, 0.062))
	bark.albedo_texture = _noise_tex(0.05)
	bark.uv1_triplanar = true
	bark.uv1_scale = Vector3(0.8, 0.12, 0.8)
	# yakın arka: gerçek 3D gövdeler (fener ışığını alır)
	var x := -12.0
	while x < 70.0:
		x += rng.randf_range(2.2, 4.8)
		var z := rng.randf_range(-4.8, -1.6)
		if _in_gap(x):
			continue
		_trunk(Vector3(x, gy_at(x, z) - 0.2, z), rng.randf_range(0.17, 0.36), bark, rng)
	# ön plan: kameraya yakın, koyu, kalın gövdeler
	for fx in [-4.0, 15.5, 53.0]:
		var z2 := rng.randf_range(3.5, 5.5)
		var m := _mat(Color(0.02, 0.02, 0.022))
		_trunk(Vector3(fx, gy_at(fx, z2) - 0.5, z2), rng.randf_range(0.35, 0.55), m, rng, false)
	# uzak katmanlar: siluet ağaçlar (sis rengini alır)
	var names := ["agac_ince", "agac_kalin", "agac_kuru_cam", "agac_olu", "agac_cift", "agac_genc"]
	for layer in [[-7.0, -11.0, 3.0], [-12.0, -18.0, 3.6], [-19.0, -28.0, 4.5], [-29.0, -40.0, 5.5]]:
		x = -20.0
		while x < 90.0:
			x += rng.randf_range(float(layer[2]) * 0.6, float(layer[2]) * 1.4)
			var z := rng.randf_range(layer[1], layer[0])
			var gx := clampf(x, -16.0, 67.0)
			var gy := gy_at(gx, z) - 0.3
			if x > 67.0:
				gy = -14.0 - (x - 67.0) * 0.3
			_sprite(names[rng.randi() % names.size()], Vector3(x, gy, z), rng.randf_range(9.0, 15.0), 1.0, rng.randf() < 0.5)

func _trunk(pos: Vector3, r: float, m: Material, rng: RandomNumberGenerator, shadow := true) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r * 0.62
	cm.bottom_radius = r
	cm.height = 22.0
	cm.radial_segments = 14
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos + Vector3(0, 11.0, 0)
	mi.rotation.z = rng.randf_range(-0.05, 0.05)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# kök yayılması ve bir iki dal
	var root := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = r
	rm.bottom_radius = r * 1.7
	rm.height = 0.6
	rm.radial_segments = 14
	root.mesh = rm
	root.material_override = m
	root.position = pos + Vector3(0, 0.3, 0)
	add_child(root)
	for k in rng.randi_range(0, 2):
		var br := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.015
		bm.bottom_radius = r * 0.3
		bm.height = rng.randf_range(1.5, 3.0)
		bm.radial_segments = 6
		br.mesh = bm
		br.material_override = m
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		br.position = pos + Vector3(side * bm.height * 0.35, rng.randf_range(3.5, 7.5), 0)
		br.rotation.z = -side * rng.randf_range(0.7, 1.2)
		add_child(br)

func _shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

func _build_sky() -> void:
	# ufukta açık, yukarıda koyulaşan sis perdesi + yavaş akan bulut dokusu
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(900, 320)
	q.mesh = qm
	q.position = Vector3(30, 40, -160)
	var m := _shader_mat("""shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D nz : repeat_enable, filter_linear_mipmap;
uniform vec3 top_c = vec3(0.24, 0.27, 0.3);
uniform vec3 hor_c = vec3(0.6, 0.62, 0.62);
void fragment() {
	float y = UV.y;
	vec3 c = mix(top_c, hor_c, smoothstep(0.0, 0.75, y));
	float n = texture(nz, UV * vec2(3.0, 1.2) + vec2(TIME * 0.004, 0.0)).r;
	c += (n - 0.5) * 0.08 * (1.0 - y);
	ALBEDO = c;
}""")
	m.set_shader_parameter("nz", _noise_tex(0.012, 512))
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(q)

func _build_fx() -> void:
	# ışık huzmeleri (ağaçların arasından süzülen)
	var shaft := """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float strength = 0.12;
uniform float seed = 0.0;
void fragment() {
	float x = UV.x;
	float edge = smoothstep(0.0, 0.4, x) * (1.0 - smoothstep(0.6, 1.0, x));
	float fade = smoothstep(0.0, 0.25, UV.y) * (1.0 - smoothstep(0.45, 1.0, UV.y));
	float n = 0.7 + 0.3 * sin(x * 17.0 + seed + TIME * 0.25) * sin(x * 7.0 - TIME * 0.17 + seed * 2.0);
	ALBEDO = vec3(1.0, 0.97, 0.9) * strength * edge * fade * n;
}"""
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var sx := -6.0
	while sx < 70.0:
		sx += rng.randf_range(6.0, 11.0)
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(rng.randf_range(1.5, 3.5), 26.0)
		mi.mesh = qm
		var m := _shader_mat(shaft)
		m.set_shader_parameter("strength", rng.randf_range(0.16, 0.3))
		m.set_shader_parameter("seed", rng.randf() * 10.0)
		mi.material_override = m
		mi.position = Vector3(sx, 9.0, rng.randf_range(-9.0, -3.0))
		mi.rotation.z = -0.38
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# arka sis katmanları (yavaş akan)
	var fog_code := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D nz : repeat_enable, filter_linear_mipmap;
uniform vec3 col = vec3(0.47, 0.5, 0.52);
uniform float dens = 0.3;
uniform float speed = 0.01;
void fragment() {
	float n = texture(nz, UV * vec2(5.0, 0.8) + vec2(TIME * speed, 0.0)).r;
	float n2 = texture(nz, UV * vec2(2.0, 0.5) - vec2(TIME * speed * 0.6, 0.3)).r;
	ALBEDO = col;
	ALPHA = clamp(dens * smoothstep(0.25, 0.75, n * 0.6 + n2 * 0.6) * smoothstep(0.0, 0.6, UV.y) * (1.0 - smoothstep(0.85, 1.0, UV.y)), 0.0, 1.0);
}"""
	var ntx := _noise_tex(0.01, 512)
	for spec in [[-6.0, 0.22, 0.008, 5.0], [-10.0, 0.3, 0.006, 6.0], [-17.0, 0.4, 0.004, 8.0], [-26.0, 0.5, 0.003, 10.0]]:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(240, spec[3])
		mi.mesh = qm
		var m := _shader_mat(fog_code)
		m.set_shader_parameter("nz", ntx)
		m.set_shader_parameter("dens", spec[1])
		m.set_shader_parameter("speed", spec[2])
		mi.material_override = m
		mi.position = Vector3(30, float(spec[3]) * 0.35 - 0.5, spec[0])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# havada asılı toz zerreleri
	dust = CPUParticles3D.new()
	dust.amount = 140
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(9, 4, 3)
	dust.direction = Vector3(1, 0.2, 0)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.12
	dust.gravity = Vector3(0.03, -0.01, 0)
	var dq := QuadMesh.new()
	dq.size = Vector2(0.018, 0.018)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.albedo_color = Color(1, 0.95, 0.85, 0.5)
	dq.material = dm
	dust.mesh = dq
	dust.local_coords = false
	add_child(dust)
	# düşen yapraklar
	leaves = CPUParticles3D.new()
	leaves.amount = 7
	leaves.lifetime = 8.0
	leaves.preprocess = 8.0
	leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents = Vector3(9, 0.5, 3)
	leaves.gravity = Vector3(0.25, -0.45, 0)
	leaves.initial_velocity_min = 0.0
	leaves.initial_velocity_max = 0.2
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.angle_max = 360.0
	var lq := QuadMesh.new()
	lq.size = Vector2(0.09, 0.09)
	var lm := StandardMaterial3D.new()
	lm.albedo_texture = load("res://assets/efekt/yaprak.png")
	lm.albedo_color = Color(0.45, 0.36, 0.3)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	lm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	lq.material = lm
	leaves.mesh = lq
	leaves.local_coords = false
	add_child(leaves)

func _build_sisli() -> void:   # uzakta bekleyen bir Sisli: yaklaşınca dağılır
	for i in 4:
		sisli_tex.append(load("res://assets/sisli/idle_%d.png" % i))
	sisli = Sprite3D.new()
	sisli.texture = sisli_tex[0]
	sisli.pixel_size = 1.55 / float(sisli_tex[0].get_height())
	sisli.offset = Vector2(0, sisli_tex[0].get_height() / 2.0)
	sisli.position = Vector3(30.3, ground_y(30.3) - 0.05, -5.5)
	sisli.flip_h = true
	sisli.shaded = false
	sisli.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sisli.modulate = Color(1, 1, 1, 0)
	add_child(sisli)

func _build_ribbon() -> void:   # son: babanın dala bağladığı kırmızı kurdele
	var tz := -0.9
	var bark := _mat(Color(0.07, 0.062, 0.055))
	var tr := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.42
	cm.height = 22.0
	tr.mesh = cm
	tr.material_override = bark
	tr.position = Vector3(RIBBON_X + 1.0, ground_y(RIBBON_X + 1.0) + 10.8, tz)
	add_child(tr)
	var br := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.025
	bm.bottom_radius = 0.09
	bm.height = 2.2
	br.mesh = bm
	br.material_override = bark
	br.position = Vector3(RIBBON_X + 0.15, ground_y(RIBBON_X) + 1.95, -0.45)
	br.rotation = Vector3(0.3, 0, -1.25)
	add_child(br)
	var red := _mat(Color(0.55, 0.04, 0.035), 0.8)
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	red.emission_enabled = true
	red.emission = Color(0.35, 0.02, 0.02)
	red.emission_energy_multiplier = 1.2
	for k in 2:
		var mi := MeshInstance3D.new()
		var im := ImmediateMesh.new()
		mi.mesh = im
		mi.material_override = red
		add_child(mi)
		ribbon_meshes.append(im)
		var pts := []
		for i in 9:
			pts.append(Vector3(RIBBON_X, ground_y(RIBBON_X) + 1.9 - i * 0.08, -0.3))
		ribbon_pts.append({"p": pts, "o": pts.duplicate()})
	var knot := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.08
	knot.mesh = sm
	knot.material_override = red
	knot.position = Vector3(RIBBON_X, ground_y(RIBBON_X) + 1.92, -0.3)
	add_child(knot)

func _build_valley() -> void:   # uçurumun ötesi: sis içinde uzak köyün ışıkları
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var m := _shader_mat("""shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform float a = 1.0;
void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d) * 2.0;
	float core = (1.0 - smoothstep(0.0, 0.25, r));
	float halo = (1.0 - smoothstep(0.0, 1.0, r)) * 0.25;
	ALBEDO = vec3(1.0, 0.6, 0.25) * (core + halo) * a;
}""")
	for i in 26:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		var s := rng.randf_range(0.7, 1.5)
		q.size = Vector2(s, s)
		mi.mesh = q
		mi.material_override = m
		mi.position = Vector3(rng.randf_range(80, 112), rng.randf_range(-1.5, 2.5), rng.randf_range(-34, -22))
		add_child(mi)

# ================================================================ oyuncu yardımcıları
func crate_at(p: Node3D, dir: int) -> Node:
	if crate == null:
		return null
	var front := p.position.x + dir * 0.2
	var face := crate.position.x - dir * 0.5
	if absf(front - face) < 0.08 and crate.position.y < p.position.y + 0.5 and crate.top() > p.position.y + 0.35:
		return crate
	return null

func find_ledge(p: NehirProto, airborne: bool, move_dir: float) -> Dictionary:
	var list := ledges.duplicate()
	if crate != null:
		list.append({"p": Vector3(crate.position.x - 0.5, crate.top(), 0), "dir": 1, "low": false, "cap": 0.62})
		list.append({"p": Vector3(crate.position.x + 0.5, crate.top(), 0), "dir": -1, "low": false, "cap": 0.62})
	for lg: Dictionary in list:
		var lp: Vector3 = lg["p"]
		var dir: int = lg["dir"]
		var dx := (lp.x - p.position.x) * dir
		var dy := lp.y - p.position.y
		if airborne:
			if p.face != dir or int(signf(move_dir)) == -dir:
				continue
			if dx < 0.12 or dx > 0.48 or dy < 0.3 or dy > (1.92 if p.mocap == null else 1.3):
				continue
			if p.velocity.y > 5.0 and dy > 1.2:
				continue
			if p.mocap != null and (p.velocity.y > 0.5 or dy > 1.1):
				continue
			return lg
		elif bool(lg.get("low", false)):
			if int(signf(move_dir)) != dir:
				continue
			if dx < 0.1 or dx > 0.36 or dy < 0.2 or dy > 0.8:
				continue
			return lg
	return {}

## Yerde, zıplama tuşuyla: önündeki 0.4–1.3 m yüksekliğindeki kenara tırman (kasa, kaya, kütük)
func find_ledge_ground(p: NehirProto) -> Dictionary:
	var list := ledges.duplicate()
	if crate != null:
		list.append({"p": Vector3(crate.position.x - 0.5, crate.top(), 0), "dir": 1, "low": false, "cap": 0.62})
		list.append({"p": Vector3(crate.position.x + 0.5, crate.top(), 0), "dir": -1, "low": false, "cap": 0.62})
	for lg: Dictionary in list:
		var lp: Vector3 = lg["p"]
		var dir: int = lg["dir"]
		if p.face != dir:
			continue
		var dx := (lp.x - p.position.x) * dir
		var dy := lp.y - p.position.y
		if dx >= 0.15 and dx <= 0.75 and dy >= 0.35 and dy <= 1.3:
			return lg
	return {}

# ================================================================ akış
func _on_died() -> void:
	phase = "dead"
	dead_t = 0.0

## Zemin türü (adım sesi): kasa üstü tahta, kaya düzlüğü taş, aşağı patika toprak, orman yaprak
func surface_at(p: Node3D) -> String:
	if crate != null and absf(p.position.y - crate.top()) < 0.12 and absf(p.position.x - crate.position.x) < 0.6:
		return "tahta"
	if p.position.x > PLAT_A and p.position.y > 1.2:
		return "kaya"
	if p.position.x > 34.0 and p.position.x < PLAT_A:
		return "toprak"
	return "yaprak"

func _build_chaser() -> void:   # kasa bölümünde peşine düşen Sisli
	for i in 4:
		chase_tex.append(load("res://assets/sisli/kos_%d.png" % i))
	chaser = Sprite3D.new()
	chaser.texture = chase_tex[0]
	chaser.pixel_size = 1.6 / 190.0
	chaser.offset = Vector2(0, chase_tex[0].get_height() / 2.0)
	chaser.shaded = false
	chaser.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	chaser.modulate = Color(1, 1, 1, 0)
	chaser.position = Vector3(34.8, -0.55, 0.15)
	chaser.visible = false
	add_child(chaser)

func _update_chase(dt: float) -> void:
	var px := player.position.x
	var py := player.position.y
	match chase:
		"off":
			if phase == "play" and px > 39.0 and px < PLAT_A and py < 1.5:
				chase = "rise"
				chase_t = 0.0
				chase_x = 34.9
				chaser.visible = true
				Game.shake(0.25)
				audio.play("yakalandi", -22.0, 0.0)
		"rise":   # uçurumun kenarından sisin içinden yükselir
			chase_t += dt
			chaser.modulate.a = minf(0.92, chase_t / 1.2)
			if chase_t > 1.3:
				chase = "run"
				chase_t = 0.0
		"run":
			chase_t += dt
			var v := lerpf(0.42, 0.72, clampf(chase_t / 5.0, 0.0, 1.0))
			if px - chase_x > 7.0:
				v += 0.4   # çok geride kalırsa biraz hızlanır
			chase_x = minf(chase_x + v * dt, PLAT_A - 0.45)
			if py > 1.3:   # oyuncu kayaya çıktı: dibinde kalır, dağılır
				chase = "stop"
				chase_t = 0.0
			elif not caught and phase == "play" and absf(chase_x - px) < 0.5 and py < ground_y(chase_x) + 1.3:
				caught = true
				audio.play("yakalandi", -2.0, 0.0)
				player.state = "cut"
				player.caught = true
				player.cut_target_x = INF
				player.velocity = Vector3.ZERO
				phase = "dead"
				dead_t = 0.3
		"stop":
			chase_t += dt
			chaser.modulate.a = maxf(0.0, 0.92 - chase_t / 2.5)
			if chase_t > 2.6:
				chase = "done"
				chaser.visible = false
	chaser.position.x = chase_x
	chaser.position.y = ground_y(chase_x) - 0.05
	chaser.texture = chase_tex[int(t * (9.0 if chase == "run" else 4.0)) % 4]
	var dist := absf(chase_x - px) if chase in ["rise", "run"] else 99.0
	audio.danger = clampf(1.0 - (dist - 0.8) / 8.0, 0.0, 1.0) if dist < 50.0 else 0.0
	if chase == "run":
		player.look_at = Vector3.INF

func _respawn() -> void:
	var c: Vector2 = CHECKPOINTS[cp]
	player.state = "ground"
	player.velocity = Vector3.ZERO
	player.position = Vector3(c.x, c.y + 0.05, 0)
	player.face = 1
	cam_pos = Vector3(c.x + 1.0, c.y + 1.3, cam_dist)
	phase = "play"
	caught = false
	player.caught = false
	if chase in ["rise", "run"]:
		chase = "off"
		chaser.visible = false
		chaser.modulate.a = 0.0

func _process(dt: float) -> void:
	t += dt
	_read_input()
	# kontrol noktaları
	for i in range(CHECKPOINTS.size() - 1, -1, -1):
		if player.position.x >= CHECKPOINTS[i].x and player.position.y > CHECKPOINTS[i].y - 1.0 and i > cp:
			cp = i
			break
	match phase:
		"intro":
			fade.color.a = maxf(0.0, 1.0 - t / 3.0)
			if t > 1.2:
				phase = "play"
		"dead":
			dead_t += dt
			fade.color.a = clampf((dead_t - 0.9) / 0.6, 0.0, 1.0)
			if dead_t > 1.6:
				_respawn()
		"play":
			fade.color.a = maxf(0.0, fade.color.a - dt * 0.8)
			if player.position.x > RIBBON_X - 1.6 and player.position.y > 1.2 and player.state == "ground":
				phase = "end"
				end_t = 0.0
				player.state = "cut"
				player.cut_target_x = RIBBON_X - 0.35
		"end":
			_end_seq(dt)
	_update_camera(dt)
	_update_world(dt)
	_update_chase(dt)
	# bakış hedefi: izleyen Sisli, sonra kurdele
	if sisli_a > 0.2:
		player.look_at = sisli.position + Vector3(0, 1.3, 0)
	elif player.position.x > RIBBON_X - 6.0 and player.position.y > 1.2:
		player.look_at = Vector3(RIBBON_X, ground_y(RIBBON_X) + 1.6, 0)
	elif chase != "run":
		player.look_at = Vector3.INF
	# rüzgârda sallanan bitkiler (yalnızca kameraya yakın olanlar)
	var wind := 0.6 + 0.4 * sin(t * 0.7) + 0.3 * sin(t * 2.3)
	for v: Array in veg:
		var sp: Sprite3D = v[0]
		if absf(sp.position.x - cam_pos.x) < 13.0:
			sp.rotation.z = sin(t * 1.6 + float(v[1]) + sp.position.x * 0.6) * 0.045 * wind - 0.02 * wind
	# ipucu metni: ilk saniyelerde görünür, hareket edince söner
	hint_t += dt
	var ha := clampf((hint_t - 2.0) / 1.0, 0.0, 1.0) * clampf((9.0 - hint_t) / 1.5, 0.0, 1.0)
	hint.modulate.a = ha * 0.8
	post.set_shader_parameter("t", fmod(t, 100.0))

func _end_seq(dt: float) -> void:
	end_t += dt
	if end_t > 1.0 and not music_on:
		music_on = true
		audio.final_music()
	if end_t > 1.6 and end_t <= 4.2:
		player.reach = minf(1.0, player.reach + dt * 0.9)
	elif end_t > 4.2:
		player.reach = maxf(0.0, player.reach - dt * 1.2)   # kol iner, sonra yürür
	if end_t > 5.6:
		player.face = 1
		player.cut_target_x = RIBBON_X + 2.6
	var ta := clampf((end_t - 5.0) / 2.0, 0.0, 1.0)
	title.modulate.a = ta * clampf((13.0 - end_t) / 1.5, 0.0, 1.0)
	if end_t > 9.0:
		fade.color.a = clampf((end_t - 9.0) / 3.0, 0.0, 1.0)
	sub.modulate.a = clampf((end_t - 12.5) / 1.5, 0.0, 1.0)
	if end_t > 12.0 and phase == "end":
		phase = "done"

func _update_camera(dt: float) -> void:
	var p := player.position
	look = lerpf(look, float(player.face) * 1.1 * clampf(absf(player.velocity.x) / 2.0, 0.3, 1.0), 1.0 - exp(-dt * 1.2))
	var dist := cam_dist
	var up := 1.0
	if p.x > 37.0 and p.x < 50.0:
		dist = 15.5   # bulmaca alanı: biraz geri çekil, kasa ve duvar birlikte görünsün
		up = 1.5
	if phase == "end" or phase == "done":
		var k := clampf((end_t - 4.5) / 6.0, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		dist = lerpf(cam_dist, 24.0, k)
		up = lerpf(1.0, 2.6, k)
		look = lerpf(look, 4.0, k * dt)
	if chase in ["rise", "run"]:   # kovalamaca: kamera açılır, Sisli de kadrajda
		var gap := absf(p.x - chase_x)
		dist = maxf(dist, 14.0 + gap * 0.45)
		look = lerpf(look, ((p.x + chase_x) * 0.5 - p.x) * 0.8, 1.0 - exp(-dt * 1.5))
	if close_cam > 0.0:
		dist = close_cam
		up = 0.75
	var target := Vector3(p.x + look, p.y + up, dist)
	if phase == "dead" or p.y < -2.0:
		target.y = maxf(target.y, cam_pos.y)
	cam_pos.x = lerpf(cam_pos.x, target.x, 1.0 - exp(-dt * 2.4))
	cam_pos.y = lerpf(cam_pos.y, target.y, 1.0 - exp(-dt * 1.9))
	cam_pos.z = lerpf(cam_pos.z, target.z, 1.0 - exp(-dt * 1.2))
	var sway := Vector3(sin(t * 0.37) * 0.04, sin(t * 0.53) * 0.03, 0.0)
	cam.position = cam_pos + sway + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * Game.shake_amt * 0.12
	var pitch := 1.5
	if phase == "end" or phase == "done":
		pitch = lerpf(1.5, -5.0, clampf((end_t - 4.5) / 6.0, 0.0, 1.0))
	cam.rotation = Vector3(deg_to_rad(pitch) + sin(t * 0.29) * 0.002, sin(t * 0.21) * 0.003, 0.0)
	dust.position = Vector3(cam_pos.x, p.y + 1.5, 0.0)
	leaves.position = Vector3(cam_pos.x + 2.0, p.y + 5.0, 0.0)

func _update_world(dt: float) -> void:
	# Sisli: uzaktan izler, yaklaşınca dağılır
	var px := player.position.x
	var want := 0.0
	if not sisli_gone and px > 21.0 and px < 29.0:
		want = 0.85
	if px > 28.0 and sisli_a > 0.3:
		sisli_gone = true
	sisli_a = move_toward(sisli_a, want, dt * (0.35 if want > 0.0 else 0.9))
	sisli.modulate.a = sisli_a
	sisli.texture = sisli_tex[int(t * 5.0) % 4]
	sisli.position.x = 30.3 + (0.0 if not sisli_gone else (1.0 - sisli_a) * 0.8)
	# kurdele rüzgârda dalgalanır
	for k in ribbon_pts.size():
		var r: Dictionary = ribbon_pts[k]
		var pts: Array = r["p"]
		var old: Array = r["o"]
		var anchor := Vector3(RIBBON_X + k * 0.03, ground_y(RIBBON_X) + 1.9, -0.3 + k * 0.02)
		var wind := Vector3(0.9 + 0.7 * sin(t * 1.3 + k) + 0.4 * sin(t * 3.7 + k * 2.0), -3.0, 0.15 * sin(t * 2.0 + k))
		pts[0] = anchor
		for i in range(1, pts.size()):
			var cur: Vector3 = pts[i]
			var v: Vector3 = (cur - (old[i] as Vector3)) * 0.96
			old[i] = cur
			pts[i] = cur + v + wind * dt * dt
		for _it in 4:
			pts[0] = anchor
			for i in range(1, pts.size()):
				var d: Vector3 = (pts[i] as Vector3) - (pts[i - 1] as Vector3)
				var l := d.length()
				if l > 0.0001:
					var diff := (l - 0.08) / l
					pts[i] = (pts[i] as Vector3) - d * diff * (1.0 if i == 1 else 0.5)
					if i > 1:
						pts[i - 1] = (pts[i - 1] as Vector3) + d * diff * 0.5
		var im: ImmediateMesh = ribbon_meshes[k]
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in pts.size():
			var a: Vector3 = pts[i]
			var nb: Vector3 = (pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)
			var dd := Vector3(nb.x, nb.y, 0).normalized()
			var n := Vector3(-dd.y, dd.x, 0)
			var wd := lerpf(0.06, 0.045, float(i) / 8.0)
			im.surface_set_normal(Vector3(0, 0, 1))
			im.surface_add_vertex(a + n * wd)
			im.surface_set_normal(Vector3(0, 0, 1))
			im.surface_add_vertex(a - n * wd)
		im.surface_end()

# ================================================================ arayüz ve girdi
func _build_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	var pr := ColorRect.new()
	pr.size = Vector2(1280, 720)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post = _shader_mat_canvas("""shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float t = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - 0.5;
	float ca = dot(d, d) * 0.004;
	vec3 c;
	c.r = texture(screen, uv + d * ca).r;
	c.g = texture(screen, uv).g;
	c.b = texture(screen, uv - d * ca).b;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 sh = vec3(0.92, 0.98, 1.06);
	vec3 hi = vec3(1.04, 1.0, 0.95);
	c *= mix(sh, hi, smoothstep(0.1, 0.7, l));
	float v = (1.0 - smoothstep(0.25, 0.95, length(d * vec2(1.0, 0.8))));
	c *= mix(0.55, 1.0, v);
	float g = h(uv * vec2(1280.0, 720.0) + fract(t * 7.0) * 100.0) - 0.5;
	c += g * 0.04;
	COLOR = vec4(c, 1.0);
}""")
	pr.material = post
	cl.add_child(pr)
	fade = ColorRect.new()
	fade.size = Vector2(1280, 720)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(fade)
	hint = _label("← →  /  parmağını kaydır : yürü, koş        ↑  /  yukarı kaydır : zıpla", 20, Vector2(0, 640))
	hint.modulate.a = 0.0
	cl.add_child(hint)
	title = _label("Kurdeleleri takip et.", 40, Vector2(0, 150))
	title.modulate.a = 0.0
	cl.add_child(title)
	sub = _label("SİS  ·  prototip bölüm\n\ndokun ya da bir tuşa bas", 22, Vector2(0, 230))
	sub.modulate.a = 0.0
	cl.add_child(sub)
	var mb := Button.new()
	mb.text = "≡"
	mb.flat = true
	mb.position = Vector2(14, 10)
	mb.size = Vector2(48, 44)
	mb.modulate.a = 0.35
	mb.add_theme_font_size_override("font_size", 26)
	mb.pressed.connect(_back_to_menu)
	cl.add_child(mb)

func _shader_mat_canvas(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

func _label(txt: String, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = Vector2(1280, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.86, 0.86, 0.84))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _read_input() -> void:
	if test != "" and not bot.is_empty():
		return
	if phase == "done":
		return
	var kx := Input.get_action_strength("right") - Input.get_action_strength("left")
	var tx := 0.0
	if _first >= 0 and _touch.has(_first):
		var f: Dictionary = _touch[_first]
		var dx: float = (f["pos"] as Vector2).x - (f["start"] as Vector2).x
		tx = clampf(dx / 120.0, -1.0, 1.0) if absf(dx) > 12.0 else 0.0
	player.input_x = kx if absf(kx) > 0.0 else tx
	if Input.is_action_just_pressed("jump"):
		player.jump_pressed = true
	player.grab_held = Input.is_action_pressed("grab") or _touch.size() >= 2

func _input(ev: InputEvent) -> void:
	if phase == "done" and ((ev is InputEventKey and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)):
		_back_to_menu()
		return
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_back_to_menu()
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_touch[ev.index] = {"start": ev.position, "pos": ev.position, "t": t, "ly": ev.position.y, "lt": t}
			if _first < 0:
				_first = ev.index
				_jumped_swipe = false
		else:
			_touch.erase(ev.index)
			if ev.index == _first:
				_first = -1
	elif ev is InputEventScreenDrag and _touch.has(ev.index):
		var f: Dictionary = _touch[ev.index]
		f["pos"] = ev.position
		# yukarı hızlı kaydırma = zıpla (her kaydırmada bir kez); sonra yatay sürüklemeye devam edilebilir
		if ev.index == _first:
			if t - float(f["lt"]) > 0.25:
				f["ly"] = ev.position.y
				f["lt"] = t
			if not _jumped_swipe and float(f["ly"]) - ev.position.y > 55.0:
				player.jump_pressed = true
				_jumped_swipe = true
				f["ly"] = ev.position.y
			if ev.position.y - float(f["ly"]) > 30.0:
				_jumped_swipe = false
				f["ly"] = ev.position.y

func _back_to_menu() -> void:
	if test != "":
		return
	Sfx.set_ambient(true)
	get_tree().change_scene_to_file("res://main.tscn")

# ================================================================ test
func _run_test() -> void:
	Sfx.set_muted(true)
	if test == "protoshot":
		await _shots()
	elif test == "protoplay":
		await _play_bot(false)
	elif test == "protoplayshot":
		await _play_bot(true)
	elif test == "protodie":
		bot = {"on": true}
		await _place(30.0, 0.5)
		player.input_x = 0.35
		await _wait(3.0)
		print("OLUM faz=%s cp=%d" % [phase, cp])
		player.input_x = 0.0
		await _wait(2.5)
		print("DIRILIS faz=%s x=%.2f y=%.2f durum=%s" % [phase, player.position.x, player.position.y, player.state])
	elif test == "protocatch":
		bot = {"on": true}
		await _place(38.5, 0.5)
		player.input_x = 0.6
		await _wait(0.8)
		player.input_x = 0.0
		var tt := 0.0
		while not caught and tt < 25.0:
			await _wait(0.25)
			tt += 0.25
		print("YAKALANDI=%s sure=%.1f sisli=%.2f oyuncu=%.2f" % [caught, tt, chase_x, player.position.x])
		await _wait(2.0)
		print("DEVAM faz=%s x=%.2f cp=%d kovalama=%s" % [phase, player.position.x, cp, chase])
	elif test == "protoclimb":
		bot = {"on": true}
		chase = "done"
		close_cam = 6.0
		crate.position = Vector3(46.0, ground_y(46.0), 0)
		await _place(45.1, 1.0)
		player.input_x = 0.0
		player.jump_pressed = true
		var k := 0
		var tt := 0.0
		while tt < 1.2:
			await _wait(0.1)
			tt += 0.1
			k += 1
			print("TIRMAN t=%.1f x=%.2f y=%.2f durum=%s" % [tt, player.position.x, player.position.y, player.state])
			await _shot("tir_%02d" % k)
		player.input_x = 0.0
	elif test == "protolog":
		bot = {"on": true}
		chase = "done"
		close_cam = 5.0
		await _place(LOG_X - 1.6, 0.8)
		player.input_x = 0.45
		var k2 := 0
		while player.state != "climb":
			await _wait(0.01)
		for _i in 8:
			k2 += 1
			await _shot("log_%02d" % k2)
			await _wait(0.09)
		player.input_x = 0.0
		close_cam = 0.0
		await _place(RIBBON_X - 4.0, 0.3)
		player.input_x = 0.6
		var et := 0.0
		while et < 9.0:
			await _wait(0.5)
			et += 0.5
			if et in [3.0, 4.5, 6.0, 7.5]:
				print("SON end_t=%.1f reach=%.2f x=%.2f" % [end_t, player.reach, player.position.x])
				k2 += 1
				await _shot("log_%02d" % k2)
	elif test == "protofloor":
		bot = {"on": true}
		var sp := get_world_3d().direct_space_state
		for xx in [33.95, 34.0, 34.1, 34.3, 34.6, 35.0, 36.0, 38.0, 45.0, 47.0, 50.0]:
			var q := PhysicsRayQueryParameters3D.create(Vector3(xx, 5, 0), Vector3(xx, -20, 0), 1)
			var r := sp.intersect_ray(q)
			print("ZEMIN x=%.2f -> %s (beklenen %.2f)" % [xx, str(r.get("position", "YOK")), ground_y(xx)])
	elif test == "protopose":
		await _pose_shots()
	get_tree().quit()

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../%s.png" % n)
	print("SHOT ", n)

func _place(x: float, settle := 1.2) -> void:
	player.state = "ground"
	player.climb = {}
	player.position = Vector3(x, ground_y(x) + 0.1, 0)
	player.velocity = Vector3.ZERO
	cam_pos = Vector3(x + 1.0, ground_y(x) + 1.0, cam_dist)
	phase = "play"
	fade.color.a = 0.0
	await _wait(settle)

func _shots() -> void:
	bot = {"on": true}
	await _place(3.0)
	await _shot("proto_1_basla")
	player.input_x = 1.0
	await _wait(0.7)
	await _shot("proto_2_kos")
	player.input_x = 0.0
	await _place(26.5)
	await _shot("proto_3_sisli")
	await _place(39.0)
	await _shot("proto_4_kasa")
	await _place(57.0)
	await _shot("proto_5_tepe")
	await _place(38.0, 0.3)
	player.input_x = 0.7
	await _wait(1.0)
	player.input_x = 0.6
	await _wait(3.5)
	await _shot("proto_6_kovalama")
	player.input_x = 0.0

## Botla baştan sona oyna: kütük, uçurum, kasa, duvar, son.
func _play_bot(shots: bool) -> void:
	bot = {"on": true}
	phase = "play"
	fade.color.a = 0.0
	var log := []
	var t0 := Time.get_ticks_msec()
	var steps := [
		["jump_at", LOG_X - 0.9], ["jump_at", 32.3], ["run_to", 39.2], ["push_stuck"], ["back_to", 44.6],
		["walk_to", 45.1], ["jump_hold_low"], ["wait_ground"], ["walk_to", 46.2], ["wait", 0.2], ["jump_hold"], ["wait_ground"],
		["run_to", 61.5],
	]
	var shot_i := 0
	for s: Array in steps:
		var ok := await _bot_step(s)
		var line := "%s -> x=%.2f y=%.2f state=%s cp=%d ok=%s sisli=%s@%.2f" % [str(s), player.position.x, player.position.y, player.state, cp, ok, chase, chase_x]
		print("BOT ", line)
		log.append(line)
		if shots and s[0] in ["jump_at", "push_stuck", "jump_hold"]:
			shot_i += 1
			await _shot("bot_%d" % shot_i)
		if not ok:
			print("BOT BASARISIZ")
			return
	var tt := 0.0
	while phase != "done" and tt < 25.0:
		await _wait(0.25)
		tt += 0.25
		if shots and tt == 5.0:
			await _shot("bot_end1")
		if shots and tt == 10.0:
			await _shot("bot_end2")
	print("BOT BITIS phase=%s sure=%.1fs" % [phase, (Time.get_ticks_msec() - t0) / 1000.0])

func _bot_step(s: Array) -> bool:
	var tt := 0.0
	match s[0]:
		"run_to", "walk_to", "push_to":
			var tx: float = s[1]
			var spd := 1.0 if s[0] == "run_to" else 0.5
			while absf(player.position.x - tx) > 0.08 and tt < 30.0:
				if phase == "dead":
					return false
				if player.state == "climb":
					player.input_x = 0.0
				else:
					player.input_x = spd * signf(tx - player.position.x)
				await _wait(0.02)
				tt += 0.02
				if s[0] == "push_to" and absf(player.position.x - tx) < 0.5:
					spd = 0.3
			player.input_x = 0.0
			await _wait(0.15)
			return tt < 30.0
		"back_to":
			var tx2: float = s[1]
			while player.position.x > tx2 and tt < 10.0:
				player.input_x = -1.0
				await _wait(0.02)
				tt += 0.02
			player.input_x = 0.0
			await _wait(0.4)
			player.input_x = 0.3
			await _wait(0.06)
			player.input_x = 0.0
			return true
		"jump_at":
			var jx: float = s[1]
			while player.position.x < jx and tt < 20.0:
				player.input_x = 1.0
				await _wait(0.01)
				tt += 0.01
			player.jump_pressed = true
			await _wait(0.1)
			while (player.state == "air" or player.state == "climb") and tt < 26.0:
				await _wait(0.02)
				tt += 0.02
				if OS.get_environment("IZ") != "":
					print("  iz x=%.2f y=%.2f vy=%.2f %s" % [player.position.x, player.position.y, player.velocity.y, player.state])
			player.input_x = 0.0
			await _wait(0.2)
			return phase != "dead"
		"push_stuck":
			var lastx := player.position.x
			var still := 0.0
			while still < 0.6 and tt < 30.0:
				player.input_x = 0.6
				await _wait(0.05)
				tt += 0.05
				if absf(player.position.x - lastx) < 0.004:
					still += 0.05
				else:
					still = 0.0
				lastx = player.position.x
			player.input_x = 0.0
			print("BOT kasa x=%.2f" % crate.position.x)
			return crate.position.x > 45.8
		"jump":
			player.jump_pressed = true
			player.input_x = 1.0
			await _wait(0.05)
			while (player.state == "air" or player.state == "climb") and tt < 6.0:
				await _wait(0.02)
				tt += 0.02
			return phase != "dead"
		"jump_hold_low":
			player.jump_pressed = true
			await _wait(0.05)
			while (player.state == "air" or player.state == "climb") and tt < 6.0:
				await _wait(0.02)
				tt += 0.02
			return phase != "dead" and player.position.y > 0.3
		"jump_hold":
			player.input_x = 1.0
			player.jump_pressed = true
			await _wait(0.05)
			while (player.state == "air" or player.state == "climb") and tt < 6.0:
				await _wait(0.02)
				tt += 0.02
			player.input_x = 0.0
			return phase != "dead" and player.position.y > 1.2
		"wait_ground":
			while player.state != "ground" and tt < 6.0:
				await _wait(0.02)
				tt += 0.02
			return true
		"wait":
			await _wait(s[1])
			return true
	return true

## Yakın plan animasyon kareleri: her hareketin ortasında bir kare
func _pose_shots() -> void:
	bot = {"on": true}
	chase = "done"
	close_cam = 4.6
	await _place(5.0, 1.5)
	cam_pos = Vector3(player.position.x, player.position.y + 0.75, close_cam)
	await _shot("poz_01_bekle")
	player.input_x = 0.4
	await _wait(1.4)
	await _shot("poz_02_yuru")
	player.input_x = 1.0
	await _wait(1.3)
	await _shot("poz_03_kos")
	await _wait(0.13)
	await _shot("poz_04_kos2")
	player.jump_pressed = true
	await _wait(0.16)
	await _shot("poz_05_ziplama")
	while player.velocity.y > -3.0 and player.state == "air":
		await _wait(0.01)
	await _shot("poz_06_dusus")
	while player.state == "air":
		await _wait(0.005)
	await _wait(0.05)
	await _shot("poz_07_inis")
	player.input_x = 0.0
	await _place(LOG_X - 1.2, 0.8)
	player.input_x = 0.45
	while player.state != "climb":
		await _wait(0.01)
	await _wait(0.22)
	await _shot("poz_08_kutuk")
	player.input_x = 0.0
	crate.position = Vector3(43.0, ground_y(43.0), 0)
	await _place(41.5, 0.8)
	player.input_x = 0.6
	for _i in 8:
		await _wait(0.2)
		print("ITME x=%.2f kasa=%.2f push=%s w=%.2f" % [player.position.x, crate.position.x, player.pushing, player.w["push"]])
	await _shot("poz_09_itme")
	player.input_x = 0.0
	crate.position = Vector3(46.0, ground_y(46.0), 0)
	await _wait(0.3)
	player.position = Vector3(46.25, crate.top() + 0.05, 0)
	await _wait(0.8)
	player.input_x = 0.6
	player.jump_pressed = true
	while player.state != "climb":
		await _wait(0.01)
	await _wait(0.12)
	await _shot("poz_10_tutun")
	await _wait(0.35)
	await _shot("poz_11_cekil")
	await _wait(0.3)
	await _shot("poz_12_diz")
	player.input_x = 0.0
	await _place(RIBBON_X - 0.35, 0.5)
	player.state = "cut"
	player.reach = 1.0
	await _wait(1.0)
	await _shot("poz_13_uzan")
	close_cam = 0.0
	phase = "end"
	end_t = 7.0
	await _wait(3.0)
	await _shot("poz_14_vadi")

func _low_quality() -> void:   # telefon: fener gölgesi kapalı, güneş gölgesi tek parça ve kısa
	player.lamp_light.shadow_enabled = false
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 22.0
	env.glow_enabled = false
	dust.amount = 60
