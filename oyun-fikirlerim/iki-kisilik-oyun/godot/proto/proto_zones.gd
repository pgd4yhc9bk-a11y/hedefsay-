class_name ProtoZones extends Node3D
## Bölümün ikinci yarısı: kaya düzlüğünden inilen vadide
##  1) ÇARK: yolu ağır bir tahta kapı kapatır. Yanındaki demir çark saat yönünde 3 tur çevrilince kapı zincirle kalkar.
##     Dokunmatik: ekranın sağ yarısında parmakla daire çizilir. Klavye: E basılı tutulur.
##  2) NEHİR: karşı kıyıya gerilmiş bir halat ve kıyıya yanaşmış bir sandal. Nehir sandala biner, feneri pruvadaki
##     kancaya asar, halatı elleriyle çekerek karşıya geçer. Sandalsız suya giren boğulur (kontrol noktasına döner).

const WHEEL_X := 61.6
const STAND_X := 61.3            # çarka yaklaşınca durduğu yer (çevirirken çarkın tam önüne geçer)
const GATE_X := 64.6
const TURNS := 3.0
const LAKE_A := 67.6             # nehir kıyıları
const LAKE_B := 79.4
const WATER_Y := -0.78
const DOCK_A := 68.75            # sandalın merkezi: berideki iskele
const DOCK_B := 78.3             # karşı iskele
const BOAT_HALF := 1.1
const ROPE_Z := -0.12            # halat göğüs önünde (Meshy çekme animasyonunda eller önde)
const ROPE_A := 66.9
const ROPE_B := 80.1

const ELEV_X := 83.85             # zincirli asansör (kayalığın dibinde)
const ELEV_HALF := 0.6
const ELEV_BOT := -0.43
const ELEV_TOP := 4.2

var lv: Node                     # ProtoLevel
var pl: NehirProto
var audio: ProtoAudio

# çark
var wheel: Node3D
var gate: Node3D
var gate_body: StaticBody3D
var chain: Array[MeshInstance3D] = []
var turns := 0.0
var gate_open := false
var wheel_active := false
var _click := 0.0
var _vlast := {}                 # parmak -> son hareket yönü (dönüş açısı hesabı)
var _gate_snd := false
var _turn_t := 0.0               # son çevirmeden beri (animasyon için)

# nehir
var water: MeshInstance3D
var boat: Node3D
var boat_body: AnimatableBody3D
var boat_x := DOCK_A
var boat_v := 0.0
var on_boat := false
var pulling := false
var hook: Node3D
var _lan_k := 0.0                # fener: elden kancaya geçiş
var _lan_from := Vector3.ZERO
var lantern_on_hook := false
var rope_pts: Array[Vector3] = []
var wake: CPUParticles3D
var splash: CPUParticles3D
var river_snd: AudioStreamPlayer
var _rope_snd := 0.0
var _phase := 0.0                # el el üstüne çekiş ritmi

# asansör
var lift: Node3D
var lift_body: AnimatableBody3D
var lift_y := ELEV_BOT
var lift_v := 0.0
var on_lift := false
var lift_active := false         # üstünde ve yukarı çıkılabilir
var lift_chains: Array[MeshInstance3D] = []
var lift_hook: Node3D
var _hook_node: Node3D = null    # fenerin asılı olduğu kanca (sandal ya da asansör)
var _grip_pt := Vector3.INF      # çekerken ellerin ortası: zincir buradan geçer
var _pull_k := 0.0               # son çekişin etkisi (animasyon, ses)
var _fdy := {}                   # parmak -> son düşey hareket (iki parmak zıt yönde mi)
var _lift_click := 0.0
var _lift_goal := ELEV_BOT       # çekişlerle varılacak yükseklik; platform buna sınırlı hızla gider
var _last_floor_y := 0.0
var _was_floor := true
var _chain_pull := false

func setup(level: Node) -> void:
	lv = level
	pl = lv.player
	audio = lv.audio
	_build_wheel()
	_build_river()
	_build_lift()

# ================================================================ yapım
func _mat(c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

func _mesh(m: Mesh, mat: Material, pos: Vector3, parent: Node = null, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	(self if parent == null else parent).add_child(mi)
	return mi

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b

func _cyl(r: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = seg
	return c

var _wood_mat: StandardMaterial3D = null

func _wood() -> StandardMaterial3D:   # tek ortak tahta malzemesi
	if _wood_mat != null:
		return _wood_mat
	var m := _mat(Color(0.12, 0.09, 0.07), 0.95)
	_wood_mat = m
	m.albedo_texture = lv._noise_tex(0.09)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.4, 2.5, 0.4)
	return m

func _build_wheel() -> void:
	var gy: float = lv.ground_y(WHEEL_X)
	var stone := _mat(Color(0.16, 0.16, 0.17), 1.0)
	stone.albedo_texture = lv._noise_tex(0.2)
	stone.uv1_triplanar = true
	var iron := _mat(Color(0.09, 0.075, 0.065), 0.55, 0.6)
	# taş ayak
	_mesh(_box(Vector3(0.42, 0.9, 0.42)), stone, Vector3(WHEEL_X, gy + 0.45, -0.85))
	wheel = Node3D.new()
	wheel.position = Vector3(WHEEL_X, gy + 0.9, -0.5)   # ellerin döndüğü yükseklik ve uzaklık (Meshy animasyonu)
	add_child(wheel)
	var tor := TorusMesh.new()
	tor.inner_radius = 0.36
	tor.outer_radius = 0.43
	tor.rings = 24
	tor.ring_segments = 8
	_mesh(tor, iron, Vector3.ZERO, wheel, Vector3(PI / 2.0, 0, 0))
	for k in 4:   # parmaklar
		_mesh(_box(Vector3(0.78, 0.045, 0.045)), iron, Vector3.ZERO, wheel, Vector3(0, 0, k * PI / 4.0))
	_mesh(_cyl(0.07, 0.16), iron, Vector3.ZERO, wheel, Vector3(PI / 2.0, 0, 0))
	_mesh(_cyl(0.03, 0.2), _wood(), Vector3(0.4, 0, 0.1), wheel, Vector3(PI / 2.0, 0, 0))   # tutamak
	_mesh(_cyl(0.05, 0.4), iron, Vector3(0, 0, -0.2), wheel, Vector3(PI / 2.0, 0, 0))     # mil
	# kapı: iki taş direk arasında ağır tahta kapak, üstte makara
	var gg: float = lv.ground_y(GATE_X)
	for z in [-1.05, 1.05]:
		_mesh(_box(Vector3(0.45, 3.4, 0.45)), stone, Vector3(GATE_X, gg + 1.7, z))
	_mesh(_box(Vector3(0.5, 0.35, 2.6)), _wood(), Vector3(GATE_X, gg + 3.45, 0.0))
	_mesh(_cyl(0.13, 0.12, 14), iron, Vector3(GATE_X - 0.28, gg + 3.2, -0.62), null, Vector3(PI / 2.0, 0, 0))
	gate = Node3D.new()
	gate.position = Vector3(GATE_X, gg, 0.0)
	add_child(gate)
	var w := _wood()
	for k in 7:   # dikey kalaslar
		_mesh(_box(Vector3(0.14, 2.5, 0.26)), w, Vector3(0, 1.25, -0.78 + k * 0.26), gate)
	for y in [0.45, 1.3, 2.15]:   # yatay kirişler ve demir şeritler
		_mesh(_box(Vector3(0.22, 0.16, 1.85)), w, Vector3(0.04, y, 0), gate)
		_mesh(_box(Vector3(0.24, 0.04, 1.86)), iron, Vector3(0.04, y + 0.1, 0), gate)
	gate_body = StaticBody3D.new()
	gate_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.3, 2.5, 1.6)
	cs.shape = bs
	cs.position = Vector3(0, 1.25, 0)
	gate_body.add_child(cs)
	gate_body.position = gate.position
	add_child(gate_body)
	for i in 2:   # zincir: çarktan makaraya, makaradan kapıya
		var cm := _mesh(_cyl(0.018, 1.0, 6), iron, Vector3.ZERO)
		cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chain.append(cm)

func _build_river() -> void:
	# su: akıntılı, koyu, sise karışan yüzey
	water = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(LAKE_B - LAKE_A + 0.6, 54.0)
	pm.subdivide_width = 24
	pm.subdivide_depth = 60
	water.mesh = pm
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
uniform sampler2D n1 : hint_normal, repeat_enable;
uniform sampler2D n2 : hint_normal, repeat_enable;
uniform vec3 deep = vec3(0.025, 0.035, 0.042);
uniform vec3 sky = vec3(0.32, 0.35, 0.38);
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 1.7 + TIME * 0.9 + wp.z * 0.6) * 0.012 + sin(wp.z * 2.3 - TIME * 1.3) * 0.008;
}
void fragment() {
	// akıntı kameraya doğru (z+), iki ölçekte kayan dalgacıklar
	vec3 a = texture(n1, wp.xz * vec2(0.22, 0.11) + vec2(TIME * 0.006, TIME * 0.05)).rgb;
	vec3 b = texture(n2, wp.xz * vec2(0.5, 0.3) + vec2(-TIME * 0.01, TIME * 0.09)).rgb;
	NORMAL_MAP = normalize(mix(a, b, 0.45));
	NORMAL_MAP_DEPTH = 0.55;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(deep, sky, fres * 0.7);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.75;
	ALPHA = 0.96;
}"""
	var wm := ShaderMaterial.new()
	wm.shader = sh
	for k in 2:
		var nt := NoiseTexture2D.new()
		var fn := FastNoiseLite.new()
		fn.frequency = 0.02 if k == 0 else 0.05
		fn.seed = 3 + k
		nt.noise = fn
		nt.seamless = true
		nt.as_normal_map = true
		nt.bump_strength = 6.0 if k == 0 else 3.0
		nt.width = 256
		nt.height = 256
		wm.set_shader_parameter("n1" if k == 0 else "n2", nt)
	water.material_override = wm
	water.position = Vector3((LAKE_A + LAKE_B) * 0.5, WATER_Y, -12.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	# kıyı taşları ve sazlar (iki kıyı boyunca)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for side in [LAKE_A, LAKE_B]:
		var dir := -1.0 if side == LAKE_A else 1.0
		var z := -9.0
		while z < 6.0:
			z += rng.randf_range(0.5, 1.2)
			if absf(z) < 0.9:
				continue
			lv._rock(Vector3(side + dir * rng.randf_range(-0.15, 0.25), WATER_Y + rng.randf_range(-0.15, 0.05), z), Vector3(rng.randf_range(0.4, 0.8), rng.randf_range(0.3, 0.5), rng.randf_range(0.4, 0.8)), 600 + int(z * 10.0) + int(side), z < -1.0)
			if rng.randf() < 0.6:   # kıyıda (karada) ot ve çimen
				var gx: float = side + dir * rng.randf_range(0.3, 0.9)
				lv._sprite(["cimen_oku", "ot"][rng.randi() % 2], Vector3(gx, lv.gy_at(gx, z + 0.3) - 0.04, z + 0.3), rng.randf_range(0.45, 0.8), 0.6, rng.randf() < 0.5)
	# halat direkleri ve halat
	var w := _wood()
	for x in [ROPE_A, ROPE_B]:
		var gy: float = lv.ground_y(x)
		_mesh(_cyl(0.07, 1.9, 8), w, Vector3(x, gy + 0.6, ROPE_Z - 0.12))
	var ry := WATER_Y + 1.15
	var a := Vector3(ROPE_A, ry, ROPE_Z)
	var b := Vector3(ROPE_B, ry, ROPE_Z)
	var rope_m := _mat(Color(0.32, 0.27, 0.2), 1.0)
	var n := 28
	for i in n + 1:
		var u := float(i) / n
		var p := a.lerp(b, u) + Vector3(0, -0.09 * sin(PI * u), 0)
		rope_pts.append(p)
	for i in n:
		var p0 := rope_pts[i]
		var p1 := rope_pts[i + 1]
		var seg := _mesh(_cyl(0.014, p0.distance_to(p1), 5), rope_m, (p0 + p1) * 0.5)
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # ince halatın gölgesi suda kalın şerit oluyordu
		seg.look_at_from_position((p0 + p1) * 0.5, p1, Vector3.FORWARD)
		seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	_build_boat()
	# su sesi (nehre yaklaştıkça)
	river_snd = AudioStreamPlayer.new()
	if audio.streams.has("su_dongu"):
		var st: AudioStreamWAV = (audio.streams["su_dongu"][0] as AudioStreamWAV).duplicate()
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = st.data.size() / 2
		river_snd.stream = st
	river_snd.volume_db = -60.0
	add_child(river_snd)
	if not audio.muted and river_snd.stream != null:
		river_snd.play()
	splash = _ring_particles(0.35, 0.9, 10)
	splash.one_shot = true
	splash.emitting = false
	wake = _ring_particles(0.05, 1.6, 6)
	wake.emitting = false
	if OS.get_environment("NOWAKE") != "":
		wake.visible = false
		splash.visible = false
	if OS.get_environment("NOWATER") != "":
		water.visible = false
	if OS.get_environment("NOZONES") != "":
		visible = false

func _ring_particles(spread_r: float, life: float, amount: int) -> CPUParticles3D:
	var g := Gradient.new()   # su yüzünde genişleyen halka
	g.offsets = PackedFloat32Array([0.0, 0.7, 0.85, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = gt
	m.vertex_color_use_as_albedo = true
	var q := PlaneMesh.new()
	q.size = Vector2(0.5, 0.5)
	q.material = m
	var p := CPUParticles3D.new()
	p.mesh = q
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread_r
	p.direction = Vector3.ZERO
	p.spread = 0.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.3))
	sc.add_point(Vector2(1, 2.6))
	p.scale_amount_curve = sc
	var cr := Gradient.new()
	cr.set_color(0, Color(0.75, 0.8, 0.85, 0.6))
	cr.set_color(1, Color(0.75, 0.8, 0.85, 0.0))
	p.color_ramp = cr
	add_child(p)
	return p

func _hull_mesh() -> ArrayMesh:
	# sandal gövdesi: boyuna kesitler (U biçimli), uçlarda daralan ve yükselen
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L := BOAT_HALF * 2.0
	var nx := 14
	var nk := 9
	var rings: Array = []
	for i in nx + 1:
		var u := float(i) / nx
		var x := -L * 0.5 + u * L
		var taper := pow(sin(PI * u), 0.6)
		var w := 0.46 * taper + 0.02
		var dpt := 0.34 * taper + 0.04
		var rise := 0.12 * pow(absf(u - 0.5) * 2.0, 3.0)
		var ring: Array[Vector3] = []
		for k in nk + 1:
			var a := PI * float(k) / nk   # 0..PI: bir küpeşteden diğerine
			ring.append(Vector3(x, 0.18 + rise - sin(a) * dpt, cos(a) * w))
		rings.append(ring)
	for i in nx:
		for k in nk:
			var p00: Vector3 = rings[i][k]
			var p10: Vector3 = rings[i + 1][k]
			var p01: Vector3 = rings[i][k + 1]
			var p11: Vector3 = rings[i + 1][k + 1]
			for v in [p00, p10, p11, p00, p11, p01]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func _build_boat() -> void:
	boat = Node3D.new()
	add_child(boat)
	var w := _wood().duplicate() as StandardMaterial3D
	w.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(_hull_mesh(), w, Vector3.ZERO, boat)
	var dark := _mat(Color(0.08, 0.06, 0.05), 0.95)
	_mesh(_box(Vector3(1.7, 0.03, 0.62)), dark, Vector3(0, 0.0, 0), boat)       # döşeme
	_mesh(_box(Vector3(0.18, 0.04, 0.82)), w, Vector3(-0.35, 0.12, 0), boat)    # oturak
	_mesh(_box(Vector3(0.18, 0.04, 0.7)), w, Vector3(0.55, 0.12, 0), boat)
	# pruvada fener direği ve kanca
	_mesh(_cyl(0.025, 1.0, 6), dark, Vector3(BOAT_HALF - 0.22, 0.6, 0.12), boat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh(_box(Vector3(0.22, 0.03, 0.03)), dark, Vector3(BOAT_HALF - 0.14, 1.08, 0.12), boat).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hook = Node3D.new()
	hook.position = Vector3(BOAT_HALF - 0.05, 1.06, 0.12)
	boat.add_child(hook)
	boat_body = AnimatableBody3D.new()
	boat_body.collision_layer = 1
	boat_body.sync_to_physics = true
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(BOAT_HALF * 2.0 - 0.1, 0.12, 0.9)
	cs.shape = bs
	cs.position = Vector3(0, -0.06, 0)
	boat_body.add_child(cs)
	add_child(boat_body)
	_place_boat()

func _place_boat() -> void:
	var deck := Vector3(boat_x, WATER_Y + 0.13, 0.0)
	boat_body.position = deck
	var t: float = lv.t
	var bob := sin(t * 1.3) * 0.02 + sin(t * 2.1 + 1.0) * 0.01
	boat.position = deck + Vector3(0, bob - 0.02, 0)
	boat.rotation = Vector3(sin(t * 1.1) * 0.025, 0.0, sin(t * 0.8 + 0.5) * 0.015 - boat_v * 0.02)

# ================================================================ her kare
func reset_for_checkpoint(cp_x: float) -> void:
	_last_floor_y = -99.0
	if cp_x < ELEV_X:   # asansörün berisinden yeniden: asansör aşağıda
		lift_y = ELEV_BOT
		_lift_goal = ELEV_BOT
		lift_v = 0.0
		on_lift = false
	if cp_x < LAKE_A:   # nehrin berisinden yeniden: sandal iskelede bekler
		boat_x = DOCK_A
		boat_v = 0.0
	on_boat = false
	pulling = false
	lantern_on_hook = false
	pl.arm_r_target = Vector3.INF
	pl.reach = 0.0
	pl.look_at = Vector3.INF
	pl.lantern_ground = Vector3.INF
	pl.lantern_upright = false

func update(dt: float) -> void:
	_update_wheel(dt)
	_update_river(dt)
	_update_lift(dt)

func _physics_process(dt: float) -> void:
	if boat_body == null:
		return
	var px := pl.position.x
	var tv := 0.0
	if pulling:
		tv = 0.85 * signf(pl.input_x)
	boat_v = move_toward(boat_v, tv, dt * (1.2 if absf(tv) > 0.0 else 1.8))
	boat_x = clampf(boat_x + boat_v * dt, DOCK_A, DOCK_B)
	if boat_x <= DOCK_A or boat_x >= DOCK_B:
		boat_v = 0.0
	_place_boat()
	_lift_physics(dt)
	if on_boat and not docked():   # sandaldan yürüyerek suya düşmesin
		var lo := boat_x - BOAT_HALF + 0.25
		var hi := boat_x + BOAT_HALF - 0.25
		if px < lo or px > hi:
			pl.position.x = clampf(px, lo, hi)
			pl.velocity.x = 0.0

func _lift_physics(dt: float) -> void:
	if lift_body == null:
		return
	lift_body.position = Vector3(ELEV_X, lift_y, 0.0)
	lift.position = Vector3(ELEV_X, lift_y, 0.0)
	# havadayken platformdan yürüyerek düşmesin (aşağıda ya da yukarıda inebilir)
	var aloft := lift_y > ELEV_BOT + 0.15 and lift_y < ELEV_TOP - 0.05
	if on_lift and aloft and pl.is_on_floor():   # yalnız platformda dururken (atlarsa serbest: düşer)
		var lo := ELEV_X - ELEV_HALF + 0.22
		var hi := ELEV_X + ELEV_HALF - 0.22
		if pl.position.x < lo or pl.position.x > hi:
			pl.position.x = clampf(pl.position.x, lo, hi)
			pl.velocity.x = 0.0

func docked() -> bool:
	return boat_x <= DOCK_A + 0.02 or boat_x >= DOCK_B - 0.02

# ---------------------------------------------------------------- çark
func _update_wheel(dt: float) -> void:
	var px := pl.position.x
	var near: bool = not gate_open and lv.phase == "play" and absf(px - STAND_X) < 0.9 and pl.is_on_floor() and pl.state in ["ground", "cut"]
	if near != wheel_active:
		wheel_active = near
		if not near and pl.yaw_override != INF:
			_release_wheel()
		if not near:
			pl.reach = 0.0
			pl.look_at = Vector3.INF
			pl.arm_r_target = Vector3.INF
	if wheel_active:
		if Input.is_key_pressed(KEY_E) or Input.is_action_pressed("grab"):
			add_turn(dt * 0.55)
		# Meshy'den çark çevirme animasyonu geldiyse: çevirirken onu oynatır, yerinde durur
		_turn_t = maxf(0.0, _turn_t - dt)
		if _has_turn_anim():
			if _turn_t > 0.0 and pl.state == "ground":
				pl.state = "cut"
				pl.cut_target_x = WHEEL_X   # çarkın tam önüne geçer
				pl.cut_speed = 0.3
				pl.mocap.set_any("M_TurnWheel")
				pl.force_anim = "any"
				pl.yaw_override = PI / 2.0 if pl.yaw > -PI / 2.0 else -1.5 * PI   # çarka döner (sırtı kameraya)
			elif _turn_t <= 0.0 and pl.force_anim == "any" and pl.mocap.any_name == "M_TurnWheel":
				_release_wheel()
		# eller tutamakta: sol el tutamağı izler, sağ el (fener) çarkın kenarında
		if not _has_turn_anim():   # animasyon yoksa: sol el tutamağa uzanır
			var hp := wheel.to_global(Vector3(0.4, 0, 0.12))   # tutamak (çarkla döner)
			pl.reach = 1.0 if absf(pl.velocity.x) < 0.2 else 0.0
			pl.look_at = hp
	wheel.rotation.z = -turns * TAU
	# kapı zincirle kalkar (cırcır: geri düşmez)
	var k := clampf(turns / TURNS, 0.0, 1.0)
	var lift := (k * k * (3.0 - 2.0 * k)) * 2.45
	var gg: float = lv.ground_y(GATE_X)
	gate.position.y = gg + lift
	gate_body.position.y = gg + lift
	if gate_open:
		gate.position.y += sin(lv.t * 3.0) * 0.004
	# zincir parçaları: çark mili -> makara -> kapının üstü
	var pul := Vector3(GATE_X - 0.28, gg + 3.2, -0.62)
	var top := Vector3(GATE_X - 0.1, gate.position.y + 2.5, -0.45)
	_seg(chain[0], wheel.global_position + Vector3(0, 0.05, -0.18), pul)
	_seg(chain[1], pul, top)

func _seg(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	(mi.mesh as CylinderMesh).height = maxf(0.01, d.length())
	mi.look_at_from_position((a + b) * 0.5, b, Vector3.FORWARD if absf(d.normalized().dot(Vector3.FORWARD)) < 0.95 else Vector3.UP)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _has_turn_anim() -> bool:
	return pl.mocap != null and pl.mocap.has_anim("M_TurnWheel")

func _release_wheel() -> void:   # çevirme bitti: yeniden yana döner, kontrol oyuncuda
	pl.force_anim = ""
	pl.yaw_override = INF
	pl.cut_target_x = INF
	pl.cut_speed = 0.45
	if pl.state == "cut" and lv.phase == "play":
		pl.state = "ground"

## Çarkı çevir (tur cinsinden; + saat yönü). Dokunma, klavye ve test botu buradan çevirir.
func add_turn(dtr: float) -> void:
	if gate_open or not wheel_active:
		return
	var before := turns
	turns = clampf(turns + dtr, 0.0, TURNS)
	if dtr > 0.0:
		_turn_t = 0.3
	if floor(turns * 4.0) != floor(before * 4.0):   # her çeyrek turda bir tık (telefonda kısa titreşim)
		audio.play("cark", -8.0, 0.1)
		buzz(28)
		if turns > before:
			audio.play("halat", -18.0, 0.15)
	if turns > 0.15 and not _gate_snd:
		_gate_snd = true
		audio.play("kapi_kalk", -10.0, 0.0)
	if turns >= TURNS - 0.06:   # parmakla çizilen daire tam kapanmayabilir: küçük pay
		turns = TURNS
		gate_open = true
		wheel_active = false
		if pl.force_anim == "any":
			_release_wheel()
		pl.reach = 0.0
		pl.look_at = Vector3.INF
		pl.arm_r_target = Vector3.INF
		audio.play("kapi_kalk", -4.0, 0.0)
		Game.shake(0.15)
		buzz(220)

## Ekranın sağ yarısında çizilen daire: ardışık hareket yönleri arasındaki açı toplanır (ekran y aşağı: + = saat yönü)
func touch_drag(index: int, pos: Vector2, rel: Vector2) -> void:
	if not wheel_active or pos.x < lv.get_viewport().get_visible_rect().size.x * 0.5:
		_vlast.erase(index)
		return
	if rel.length() < 2.5:
		return
	if _vlast.has(index):
		var v1: Vector2 = _vlast[index]
		var ang := atan2(v1.x * rel.y - v1.y * rel.x, v1.dot(rel))
		add_turn(ang / TAU)
	_vlast[index] = rel

## Asansör: iki parmak ekranda; biri aşağı, diğeri yukarı kayarken zincir çekilir (el el üstüne).
func lift_drag(index: int, rel: Vector2, touches: int) -> void:
	if not lift_active or touches < 2:
		_fdy.clear()
		return
	_fdy[index] = rel.y
	var down := 0.0
	var up := 0.0
	for k in _fdy:
		var dy: float = _fdy[k]
		if dy > 0.0:
			down = maxf(down, dy)
		else:
			up = maxf(up, -dy)
	if down > 0.5 and up > 0.5:   # zıt yönlerde: çekiş
		add_lift(minf(down, up) * 0.004)   # ~8-9 çekişte yukarı

func is_lift_touch() -> bool:   # asansörde parmaklar zıplatmaz/yürütmez
	return lift_active

## Asansörü yükselt (metre). Dokunma, klavye (E) ve test botu buradan.
func add_lift(dy: float) -> void:
	if not lift_active:
		return
	_lift_goal = minf(ELEV_TOP, maxf(_lift_goal, lift_y) + dy)
	_lift_goal = minf(_lift_goal, lift_y + 0.6)   # bir çekiş platformu en çok 60 cm ileri taşır
	_pull_k = 0.35


func _hands_free() -> void:
	pl.reach = 0.0
	pl.look_at = Vector3.INF
	pl.arm_r_target = Vector3.INF
	pl.mocap.grip_l = 0.45

func _fall_death() -> void:   # yüksekten yere çakılma: yığılır, kontrol noktasına döner (asansör aşağı iner)
	audio.play("inis", 2.0, 0.0)
	Game.shake(0.5)
	buzz(300)
	pl.state = "cut"
	pl.caught = true
	pl.cut_target_x = INF
	pl.velocity = Vector3.ZERO
	lv.phase = "dead"
	lv.dead_t = 0.3

func buzz(ms: int) -> void:   # telefonda titreşim (izin: export_presets permissions/vibrate)
	if lv.test == "":
		Input.vibrate_handheld(ms)

func is_turn_touch(start: Vector2) -> bool:   # bu parmak çark için mi (yürütmesin)
	return wheel_active and start.x > lv.get_viewport().get_visible_rect().size.x * 0.5

# ---------------------------------------------------------------- nehir
func _update_river(dt: float) -> void:
	var px := pl.position.x
	var py := pl.position.y
	# su sesi
	var d := 0.0
	if px < LAKE_A:
		d = LAKE_A - px
	elif px > LAKE_B:
		d = px - LAKE_B
	if river_snd != null:
		river_snd.volume_db = lerpf(-12.0, -40.0, clampf(d / 14.0, 0.0, 1.0))
	# sandalda mı
	var was := on_boat
	on_boat = lv.phase == "play" and absf(px - boat_x) < BOAT_HALF and py > WATER_Y - 0.1 and py < WATER_Y + 0.5 and pl.state != "climb"
	if on_boat and not was:
		audio.play("adim_tahta", -8.0)
		boat_v += 0.05
	# çekiş: sandal kıyıdan ayrılınca ya da halatı çekerken
	var ix := pl.input_x
	var want_pull: bool = on_boat and absf(ix) > 0.25 and ((ix > 0.0 and boat_x < DOCK_B - 0.02 and px > boat_x - 0.55) or (ix < 0.0 and boat_x > DOCK_A + 0.02 and px < boat_x + 0.55))
	if want_pull != pulling:
		pulling = want_pull
		if pulling:
			pl.state = "cut"
			pl.cut_target_x = INF
			pl.velocity.x = 0.0
		else:
			if pl.state == "cut" and lv.phase == "play":
				pl.state = "ground"
			pl.arm_r_target = Vector3.INF
			pl.reach = 0.0
			pl.look_at = Vector3.INF
	var rope_anim: bool = pl.mocap != null and pl.mocap.has_anim("M_PullRope")
	if rope_anim:   # Meshy'den halat çekme animasyonu geldiyse onu oynatır; eller her karede halata yönelir (kavrar)
		if pulling and pl.force_anim == "":
			pl.mocap.set_any("M_PullRope")
			pl.force_anim = "any"
		elif not pulling and pl.force_anim == "any" and pl.mocap.any_name == "M_PullRope":
			pl.force_anim = ""
			_hands_free()
		if pulling:
			var hl: Vector3 = pl.body.bone_world("hand.L")
			var hr: Vector3 = pl.body.bone_world("hand.R")
			var ryy := _rope_y(px)
			pl.reach = 1.0
			pl.look_at = Vector3(maxf(hl.x, px + 0.3), ryy, ROPE_Z)
			pl.arm_r_target = Vector3(maxf(hr.x, px + 0.3), ryy, ROPE_Z)
			pl.mocap.grip_l = 1.9
	if pulling and not rope_anim:
		# el el üstüne: iki el sırayla halatta öne uzanıp geri çeker
		_phase += absf(boat_v) * dt * 2.2
		var fwd := signf(ix)
		var a := fmod(_phase, 1.0)
		var b := fmod(_phase + 0.5, 1.0)
		var ry := _rope_y(px)
		pl.reach = 1.0
		pl.look_at = Vector3(px + fwd * lerpf(0.55, 0.25, a), ry, ROPE_Z)
		pl.arm_r_target = Vector3(px + fwd * lerpf(0.55, 0.25, b), ry, ROPE_Z)
	if pulling:
		_rope_snd -= dt
		if _rope_snd <= 0.0 and absf(boat_v) > 0.2:
			_rope_snd = 0.55
			audio.play("halat", -16.0, 0.2)
	wake.emitting = absf(boat_v) > 0.15
	wake.position = Vector3(boat_x - signf(boat_v) * BOAT_HALF * 0.8, WATER_Y + 0.02, 0.0)
	# fener: sandaldayken pruvadaki kancada, inerken yeniden elde
	if (pulling or _chain_pull) and not lantern_on_hook and pl.lantern_left < 0.01 and pl.lantern_pick == Vector3.INF:
		lantern_on_hook = true
		_hook_node = hook if pulling else lift_hook
		_lan_k = 0.0
		_lan_from = pl.lantern.global_position
		audio.play("kumas", -14.0)
	elif lantern_on_hook and ((_hook_node == hook and not on_boat) or (_hook_node == lift_hook and not on_lift)):
		lantern_on_hook = false
		pl.lantern_pick = _hook_node.global_position
		pl.lantern_pick_w = 0.0
		var tw := create_tween()
		tw.tween_property(pl, "lantern_pick_w", 1.0, 0.25)
		pl.lantern_ground = Vector3.INF
		pl.lantern_upright = false
		audio.play("kumas", -14.0)
	if lantern_on_hook:
		_lan_k = minf(1.0, _lan_k + dt * 4.0)
		pl.lantern_ground = _lan_from.lerp(_hook_node.global_position, _lan_k * _lan_k * (3.0 - 2.0 * _lan_k))
		pl.lantern_upright = true
	# boğulma: sandalsız suya girdi
	if lv.phase == "play" and not on_boat and px > LAKE_A + 0.1 and px < LAKE_B - 0.1 and py < WATER_Y - 0.15 and pl.state != "dead":
		drown()

func _rope_y(x: float) -> float:
	var u := clampf((x - ROPE_A) / (ROPE_B - ROPE_A), 0.0, 1.0)
	return WATER_Y + 1.15 - 0.09 * sin(PI * u)

func drown() -> void:
	splash.position = Vector3(pl.position.x, WATER_Y + 0.02, 0.0)
	splash.restart()
	splash.emitting = true
	audio.play("su_sicrama", -2.0, 0.05)
	pl.state = "dead"
	pl.velocity = Vector3(pl.velocity.x * 0.2, -0.8, 0.0)
	lv._on_died()

# ---------------------------------------------------------------- zincirli asansör
func _build_lift() -> void:
	var w := _wood()
	var iron := _mat(Color(0.09, 0.075, 0.065), 0.55, 0.6)
	lift = Node3D.new()
	add_child(lift)
	_mesh(_box(Vector3(ELEV_HALF * 2.0, 0.1, 1.1)), w, Vector3(0, -0.05, 0), lift)       # platform
	lift_hook = Node3D.new()   # öndeki direğin tepesinde fener kancası
	lift_hook.position = Vector3(-ELEV_HALF + 0.08, 0.92, 0.5)
	lift.add_child(lift_hook)
	for x in [-ELEV_HALF + 0.05, ELEV_HALF - 0.05]:
		_mesh(_box(Vector3(0.08, 0.12, 1.15)), w, Vector3(x, -0.04, 0), lift)
	for z in [-0.5, 0.5]:   # kenar korkulukları (dikey direkler)
		_mesh(_box(Vector3(0.06, 0.9, 0.06)), w, Vector3(-ELEV_HALF + 0.08, 0.45, z), lift)
	lift_body = AnimatableBody3D.new()
	lift_body.collision_layer = 1
	lift_body.sync_to_physics = true
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ELEV_HALF * 2.0, 0.1, 1.0)
	cs.shape = bs
	cs.position = Vector3(0, -0.05, 0)
	lift_body.add_child(cs)
	add_child(lift_body)
	# kayalığın üstünde ağır bir ağaç darağacı ve makara
	var top := ELEV_TOP + 2.1
	_mesh(_box(Vector3(0.2, 2.4, 0.2)), w, Vector3(ELEV_X + 0.75, ELEV_TOP + 1.2, -0.75))
	_mesh(_box(Vector3(1.5, 0.18, 0.2)), w, Vector3(ELEV_X + 0.1, top, -0.75))
	_mesh(_box(Vector3(0.14, 0.14, 1.6)), w, Vector3(ELEV_X, top, 0.0))
	_mesh(_cyl(0.16, 0.12, 14), iron, Vector3(ELEV_X - 0.25, top - 0.15, 0.0), null, Vector3(PI / 2.0, 0, 0))
	for i in 4:   # iki taşıyıcı zincir + çekme zinciri (iki parça: ellere kadar ve ellerden aşağı)
		var cm := _mesh(_cyl(0.016, 1.0, 6), iron, Vector3.ZERO)
		cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lift_chains.append(cm)
	_place_lift_chains()

func _place_lift_chains() -> void:
	var top := ELEV_TOP + 2.1
	_seg(lift_chains[0], Vector3(ELEV_X - 0.5, lift_y + 0.9, -0.5), Vector3(ELEV_X - 0.25, top - 0.15, -0.5))
	_seg(lift_chains[1], Vector3(ELEV_X - 0.5, lift_y + 0.9, 0.5), Vector3(ELEV_X - 0.25, top - 0.15, 0.5))
	var ct := Vector3(ELEV_X - 0.25, top - 0.3, -0.12)
	if _grip_pt != Vector3.INF:   # çekerken: makaradan ellere, ellerden aşağı sarkar
		_seg(lift_chains[2], ct, _grip_pt)
		_seg(lift_chains[3], _grip_pt, Vector3(_grip_pt.x, lift_y + 0.15, _grip_pt.z))
		lift_chains[3].visible = true
	else:
		_seg(lift_chains[2], ct, Vector3(ELEV_X - 0.25, lift_y + 0.15, -0.12))   # önünden sarkan çekme zinciri
		lift_chains[3].visible = false

func _update_lift(dt: float) -> void:
	var px := pl.position.x
	var py := pl.position.y
	on_lift = lv.phase == "play" and absf(px - ELEV_X) < ELEV_HALF and absf(py - lift_y) < 0.25 and pl.state != "climb"
	# platform çekişlerin hedefine sınırlı hızla yükselir (animasyon görünsün)
	if lift_y < _lift_goal:
		var before := lift_y
		lift_y = minf(_lift_goal, lift_y + 0.5 * dt)
		_lift_click += lift_y - before
		if _lift_click > 0.22:   # zincir halkası takılır: tık ve titreşim
			_lift_click = 0.0
			audio.play("cark", -10.0, 0.15)
			audio.play("halat", -18.0, 0.2)
			buzz(22)
		if lift_y >= ELEV_TOP - 0.001:
			audio.play("kapi_kalk", -10.0, 0.0)
			buzz(160)
	# yüksekten (asansör ya da kayalığın tepesi) asansörün dibine düşen ölür: asansör yukarıda kaldı, geri çıkılamaz
	var fl := pl.is_on_floor()
	if fl and not _was_floor and lv.phase == "play" and _last_floor_y - py > 2.0 and px > LAKE_B and px < ELEV_X + ELEV_HALF + 0.2:
		_fall_death()
	if fl:
		_last_floor_y = py
	_was_floor = fl
	lift_active = on_lift and lift_y < ELEV_TOP - 0.01
	if lift_active and (Input.is_key_pressed(KEY_E) or Input.is_action_pressed("grab")):
		add_lift(dt * 0.55)
	_pull_k = maxf(0.0, _pull_k - dt)
	if lift_y < _lift_goal - 0.02:
		_pull_k = maxf(_pull_k, 0.1)   # platform yükselirken çekiş animasyonu sürer
	if lift_active and _pull_k > 0.0:
		# zinciri çekerken: zincirin önünde durur, eller zincirde sırayla yukarıdan aşağı çeker
		_chain_pull = true
		_phase += dt * 2.6
		var cx := ELEV_X - 0.25
		var a := fmod(_phase, 1.0)
		var b := fmod(_phase + 0.5, 1.0)
		if pl.state == "ground":
			pl.state = "cut"
		pl.cut_target_x = cx - 0.32
		pl.cut_speed = 0.3
		pl.face = 1
		if pl.mocap != null and pl.mocap.has_anim("M_PullChain"):   # Meshy'den zincir çekme animasyonu geldiyse
			if pl.force_anim == "":
				pl.mocap.set_any("M_PullChain")
				pl.force_anim = "any"
			# animasyon olduğu gibi oynar; serbest sarkan çekme zinciri ellerin arasından geçer (eller zinciri tutar)
			pl.mocap.grip_l = 1.9
			_grip_pt = (pl.body.bone_world("hand.L") + pl.body.bone_world("hand.R")) * 0.5
		else:
			pl.reach = 1.0
			pl.look_at = Vector3(cx, lift_y + lerpf(1.75, 1.05, a), -0.12)
			pl.arm_r_target = Vector3(cx, lift_y + lerpf(1.75, 1.05, b), -0.12)
	elif _chain_pull:
		_chain_pull = false
		_grip_pt = Vector3.INF
		if pl.force_anim == "any" and pl.mocap.any_name == "M_PullChain":
			pl.force_anim = ""
		pl.mocap.grip_l = 0.45
		if pl.state == "cut" and lv.phase == "play":
			pl.state = "ground"
		pl.cut_target_x = INF
		pl.cut_speed = 0.45
		pl.reach = 0.0
		pl.look_at = Vector3.INF
		pl.arm_r_target = Vector3.INF
	_place_lift_chains()
