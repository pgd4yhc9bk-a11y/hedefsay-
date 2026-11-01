class_name NehirProto extends CharacterBody3D
## Prototip bölümün oynanan karakteri: Inside tarzı ağır, yumuşak hareket.
## Fizik: yürü/koş (analog), zıpla, kenara tutun + tırman (otomatik), kasa it / çek, sert iniş.
## Animasyon: NehirBody üzerinde prosedürel pozlar; durumlar arasında yumuşak geçiş, ayaklar zemine oturur.
## Aksesuar: elde sallanan fener (ışık), rüzgârda dalgalanan kırmızı atkı, örgü saç.

signal died

const GRAV := 21.0
const WALK := 1.2
const RUN := 2.7
const JUMP_V := 6.7
const PUSH_V := 1.15
const PULL_V := 0.95
const THIGH := 0.335
const SHIN := 0.355
const LEG := 0.69

var world: Node = null          # ProtoLevel: kenarlar ve kasalar
var body                        # NehirBody (prosedürel) ya da NehirMocap
var mocap: NehirMocap = null
var land_t := 0.0
var roll_t := 0.0
var wake_t := 0.0               # açılışta yerden kalkma
var caught := false             # Sisli yakaladı (ölüm animasyonu)
var force_anim := ""              # ara sahne: zorla oynatılacak animasyon (crouch, torch)
var turn: Node3D                # yön dönüşü (Y ekseni)
var face := 1
var yaw := 0.0
var state := "ground"           # ground | air | climb | dead | cut
var input_x := 0.0
var jump_pressed := false
var grab_held := false
var cut_target_x := INF         # ara sahne: buraya yürü
var reach := 0.0                # ara sahne: kurdeleye uzanma (0..1)

var coyote := 0.0
var jump_buf := 0.0
var prev_vy := 0.0
var land_amt := 0.0
var recover := 0.0
var air_t := 0.0
var t := 0.0
var phase := 0.0
var spd := 0.0                  # yumuşatılmış yatay hız (animasyon)
var pushing := false
var pulling := false
var crate: Node = null
var _drag_t := 0.0
var _last_step := 0
var w := {"loco": 1.0, "air": 0.0, "push": 0.0, "pull": 0.0}
var climb := {}
var glance := 0.0
var _glance_t := 2.0
var _glance_target := 0.0
var hy_s := 0.0
var hard_t := 0.0             # sert iniş: eller yere
var exert := 0.0              # koşu yorgunluğu (nefes)
var _breath_t := 0.0
var _breath_in := true
var look_at := Vector3.INF    # kafa bu noktaya bakar (Sisli, kurdele)
var _look := 0.0
var teeter := 0.0             # uçurum kenarında sendeleme ağırlığı
var _prev_vx := 0.0
var _acc_s := 0.0
var _was_pushing := false

# aksesuarlar
var lantern: Node3D
var lamp_light: OmniLight3D
var glass_mat: StandardMaterial3D
var halo: MeshInstance3D
var halo_mat: ShaderMaterial
var lan_th := 0.0
var lan_w := 0.0
var _piv_prev := Vector3.ZERO
var _piv_vel := Vector3.ZERO
var scarf_pts: Array[Vector3] = []
var scarf_old: Array[Vector3] = []
var scarf_mesh: ImmediateMesh
var scarf_knot: MeshInstance3D
var braid_pts: Array[Vector3] = []
var braid_old: Array[Vector3] = []
var braid_balls: Array[MeshInstance3D] = []
var wind := 0.0

func _ready() -> void:
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2)
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2
	cap.height = 1.38
	cs.shape = cap
	cs.position = Vector3(0, 0.69, 0)
	add_child(cs)
	turn = Node3D.new()
	add_child(turn)
	if ResourceLoader.exists("res://proto/mocap/manken_kiz.glb") and ResourceLoader.exists("res://proto/mocap/anim.res"):
		mocap = NehirMocap.new()
		turn.add_child(mocap)
		mocap.footstep.connect(func(strength: float) -> void:
			_snd("adim_" + _surface(), -16.0 + strength * 7.0, 0.1))
		body = mocap
	else:
		body = NehirBody.new()
		turn.add_child(body)
	_build_lantern()
	_build_scarf()
	_build_braid()

# ---------------------------------------------------------------- fizik
func _physics_process(dt: float) -> void:
	t += dt
	if state == "dead":
		velocity.y -= GRAV * dt
		velocity.x *= 0.98
		position += velocity * dt
		return
	if state == "climb":
		_climb_step(dt)
		return
	var on_floor := is_on_floor()
	var ix := input_x
	if wake_t > 0.0:
		wake_t -= dt
		ix = 0.0
		jump_pressed = false
	if roll_t > 0.0:
		roll_t -= dt
		ix = float(face) * 0.7
	land_t = maxf(0.0, land_t - dt)
	if state == "cut":
		ix = 0.0
		if cut_target_x != INF:
			var d := cut_target_x - position.x
			ix = clampf(d * 1.2, -0.45, 0.45) if absf(d) > 0.04 else 0.0
	# hedef hız: analog girdi (küçük = yürü, büyük = koş)
	var a := absf(ix)
	var target := 0.0
	if a > 0.05:
		target = signf(ix) * (lerpf(0.0, WALK, a / 0.55) if a < 0.55 else lerpf(WALK, RUN, (a - 0.55) / 0.45))
	if recover > 0.0:
		recover -= dt
		target *= 0.3
	# kasa: yürüyerek it, tut + geri git: çek
	pushing = false
	pulling = false
	crate = null
	if on_floor and world != null:
		var dir := signf(target) if absf(target) > 0.05 else float(face)
		var c: Node = world.crate_at(self, int(dir))
		if c != null and absf(target) > 0.05:
			pushing = true
			crate = c
		elif grab_held and absf(target) > 0.05:
			var cb: Node = world.crate_at(self, -int(signf(target)))
			if cb != null:
				pulling = true
				crate = cb
	if pushing:
		target = signf(target) * minf(absf(target), PUSH_V if mocap == null else 0.8)
	elif pulling:
		target = signf(target) * minf(absf(target), PULL_V)
	# yön
	if not pulling and absf(ix) > 0.05 and state != "cut":
		face = 1 if ix > 0.0 else -1
	elif state == "cut" and absf(ix) > 0.05:
		face = 1 if ix > 0.0 else -1
	var acc := 4.5
	if on_floor:
		acc = 9.0 if absf(target) > absf(velocity.x) else 13.0
		if pushing or pulling:
			acc = 2.6
		if signf(target) != signf(velocity.x) and absf(velocity.x) > 0.5 and target != 0.0:
			acc = 16.0   # ani dönüş
	if (pushing or pulling) and not _was_pushing:   # kasaya değince hız kesilir, itme yavaş başlar
		velocity.x = signf(velocity.x) * minf(absf(velocity.x), 0.25)
	_was_pushing = pushing or pulling
	velocity.x = move_toward(velocity.x, target, acc * dt)
	# zıplama
	if jump_pressed:
		jump_buf = 0.15
		jump_pressed = false
	jump_buf -= dt
	coyote = 0.1 if on_floor else coyote - dt
	if mocap != null and jump_buf > 0.0 and on_floor and state != "cut" and world != null:
		var glg: Dictionary = world.find_ledge_ground(self)
		if not glg.is_empty():
			jump_buf = 0.0
			_start_climb(glg)
			return
	if jump_buf > 0.0 and coyote > 0.0 and state != "cut" and not pulling:
		velocity.y = JUMP_V
		coyote = 0.0
		jump_buf = 0.0
		state = "air"
		_snd("kumas", -14.0)
		_snd("nefes_ver", -18.0 + exert * 8.0, 0.1)
	if not on_floor:
		velocity.y -= GRAV * dt
		velocity.y = maxf(velocity.y, -18.0)
	elif velocity.y < 0.0:
		velocity.y = 0.0
	# kasa önce kayar (itme), oyuncu sonra (çekme)
	if pushing and crate != null:
		var dx := velocity.x * dt
		var moved: float = crate.slide(dx)
		if absf(moved) < absf(dx) * 0.5:
			velocity.x = moved / dt
	prev_vy = velocity.y
	var was_floor := on_floor
	var x0 := position.x
	move_and_slide()
	position.z = 0.0
	if pulling and crate != null:
		crate.slide(position.x - x0)
	if (pushing or pulling) and absf(position.x - x0) > 0.0005:
		_drag_t -= dt
		if _drag_t <= 0.0:
			_drag_t = 0.42
			_snd("kasa_surt", -11.0, 0.12)
			if randf() < 0.4:
				_snd("caba", -20.0, 0.1)
	# iniş
	if is_on_floor() and not was_floor:
		var impact := -prev_vy
		if impact > 2.0:
			land_amt = clampf((impact - 2.0) / 9.0, 0.15, 1.0)
			var lv := linear_to_db(clampf(impact / 14.0, 0.15, 1.0))
			_snd("adim_" + _surface(), lv - 6.0, 0.1)
			if impact > 7.0:
				_snd("inis", lv - 4.0)
				_snd("nefes_ver", -16.0, 0.1)
			if impact > 12.5:
				recover = 0.55
				hard_t = 0.75
				roll_t = 1.0      # sert iniş: öne yuvarlan
			elif impact > 6.5:
				land_t = 0.42
		state = "ground"
		air_t = 0.0
	if not is_on_floor():
		air_t += dt
		if state == "ground" and air_t > 0.08:
			state = "air"
	# kenara tutunma (havada) ve alçak engele tırmanma (yerde, engele doğru yürürken)
	if world != null and state != "cut":
		var lg: Dictionary = world.find_ledge(self, not is_on_floor(), signf(target) if absf(target) > 0.05 else 0.0)
		if not lg.is_empty():
			_start_climb(lg)
	if position.y < -6.0 and state != "dead":
		state = "dead"
		_snd("yakalandi", -8.0, 0.0)
		died.emit()

func _start_climb(lg: Dictionary) -> void:
	var p: Vector3 = lg["p"]
	var dir: int = lg["dir"]
	face = dir
	var dy := p.y - position.y
	var hang := dy > 1.35 and mocap == null
	var start := position
	if hang:
		start = Vector3(p.x - dir * 0.27, p.y - 1.74, 0.0)
	if mocap != null:
		# animasyonun kök hareketi: 1.39 m ileri. Kenarın ötesinde kalan kısım kenara göre sınırlanır (kasa dar).
		var ex := position.x + dir * 1.39
		var cap: float = lg.get("cap", 0.9)
		if (ex - p.x) * dir > cap:
			ex = p.x + dir * cap
		climb = {"p": p, "dir": dir, "t": 0.0, "dur": 0.67 / 0.85, "from": position, "start": position, "hang": false, "dy": dy,
			"end": Vector3(ex, p.y, 0.0), "mocap": true}
		velocity = Vector3.ZERO
		state = "climb"
		_snd("kumas", -12.0)
		_snd("caba", -16.0, 0.08)
		return
	climb = {"p": p, "dir": dir, "t": 0.0, "dur": (1.25 if hang else ((0.85 if dy > 0.8 else 0.55) if mocap == null else lerpf(0.5, 0.9, clampf(dy / 1.2, 0.0, 1.0)))), "from": position, "start": start, "hang": hang, "dy": dy}
	velocity = Vector3.ZERO
	state = "climb"
	_snd("kumas", -12.0)
	_snd("caba" if hang else "nefes_ver", -14.0 if hang else -18.0, 0.08)

func _climb_step(dt: float) -> void:
	climb["t"] += dt / float(climb["dur"])
	if climb.has("mocap"):
		var km: float = minf(1.0, climb["t"])
		position = (climb["start"] as Vector3).lerp(climb["end"], km)
		if km >= 1.0:
			state = "ground"
			climb = {}
			velocity = Vector3.ZERO
		return
	var k: float = minf(1.0, climb["t"])
	var p: Vector3 = climb["p"]
	var dir: int = climb["dir"]
	var hang: bool = climb["hang"]
	var a: Vector3 = climb["start"]
	var b := Vector3(p.x - dir * 0.20, p.y - 0.78, 0.0)
	var c := Vector3(p.x + dir * 0.03, p.y - 0.12, 0.0)
	var d := Vector3(p.x + dir * 0.34, p.y + 0.0, 0.0)
	var pos: Vector3
	if hang:
		# ilk %12: asılı noktaya yumuşak geçiş, sonra çekiş
		if k < 0.12:
			pos = (climb["from"] as Vector3).lerp(a, _ease(k / 0.12))
		elif k < 0.55:
			pos = a.lerp(b, _ease((k - 0.12) / 0.43))
		elif k < 0.82:
			pos = b.lerp(c, _ease((k - 0.55) / 0.27))
		else:
			pos = c.lerp(d, _ease((k - 0.82) / 0.18))
	else:
		var b2 := Vector3(p.x - dir * 0.12, lerpf(a.y, p.y, 0.55), 0.0)
		if k < 0.5:
			pos = a.lerp(b2, _ease(k / 0.5))
		else:
			pos = b2.lerp(d, _ease((k - 0.5) / 0.5))
	position = pos
	if k >= 1.0:
		state = "ground"
		climb = {}
		velocity = Vector3.ZERO
		_snd("adim_" + _surface(), -10.0)
		land_amt = 0.25

func _snd(n: String, vol := 0.0, pv := 0.08) -> void:
	if world != null and world.get("audio") != null:
		world.audio.play(n, vol, pv)

func _surface() -> String:
	if world != null and world.has_method("surface_at"):
		return world.surface_at(self)
	return "yaprak"

## Önünde zemin yoksa (uçurum kenarı) true
func _edge_ahead() -> bool:
	var sp := get_world_3d().direct_space_state
	var from := global_position + Vector3(face * 0.32, 0.3, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -0.9, 0), 1 | (1 << 2))
	return sp.intersect_ray(q).is_empty()

func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

# ---------------------------------------------------------------- animasyon
func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	# dönüş: kameraya doğru dönerek (Inside gibi)
	var ty := 0.0 if face > 0 else -PI
	yaw = move_toward(yaw, ty, dt * 8.5)
	turn.rotation.y = yaw
	var on_floor := is_on_floor() or state == "climb"
	var vx := velocity.x if state != "climb" else 0.0
	spd = lerpf(spd, absf(vx) if on_floor else spd, 1.0 - exp(-dt * 10.0))
	var run_b := clampf((spd - WALK) / (RUN - WALK), 0.0, 1.0)
	var stride := lerpf(1.1, 1.8, run_b)
	if pushing or pulling:
		stride = 0.75
	if on_floor:
		phase += (vx * face) * dt / stride
		var stp := int(floor(phase * 2.0))
		if stp != _last_step and absf(vx) > 0.3 and state != "climb":
			if mocap == null:
				_snd("adim_" + _surface(), -13.0 + run_b * 5.0, 0.12)
		_last_step = stp
	# yorgunluk ve nefes: koştukça artar, nefes hızlanır ve duyulur
	exert = clampf(exert + (dt * 0.12 if run_b > 0.6 and on_floor else -dt * 0.05), 0.0, 1.0)
	_breath_t -= dt
	if _breath_t <= 0.0:
		_breath_t = lerpf(1.7, 0.75, exert) * (1.1 if _breath_in else 0.9)
		if exert > 0.25:
			_snd("nefes_al" if _breath_in else "nefes_ver", lerpf(-26.0, -14.0, exert), 0.06)
		_breath_in = not _breath_in
	# ivme: harekete başlarken öne, dururken geriye yaslanma
	if state != "climb":
		var ax := (vx - _prev_vx) / maxf(dt, 0.001) * face
		_acc_s = lerpf(_acc_s, clampf(ax, -12.0, 12.0) if on_floor else 0.0, 1.0 - exp(-dt * 8.0))
	_prev_vx = vx
	# uçurum kenarında durunca sendeleme
	var want_teeter := 0.0
	if state == "ground" and is_on_floor() and spd < 0.25 and not pushing and _edge_ahead():
		want_teeter = 1.0
	teeter = move_toward(teeter, want_teeter, dt * 3.0)
	hard_t = maxf(0.0, hard_t - dt)
	if mocap != null:
		_mocap_anim(dt, run_b)
		_accessories(dt)
		return
	# kayan ağırlıklar
	var tgt := {"loco": 0.0, "air": 0.0, "push": 0.0, "pull": 0.0}
	if state == "air" or (not on_floor and state != "climb"):
		tgt["air"] = 1.0
	elif pushing:
		tgt["push"] = 1.0
	elif pulling:
		tgt["pull"] = 1.0
	else:
		tgt["loco"] = 1.0
	for k: String in w:
		w[k] = lerpf(w[k], tgt[k], 1.0 - exp(-dt * (14.0 if k == "air" else 9.0)))
	land_amt = maxf(0.0, land_amt - dt * 2.6)
	_glance_t -= dt
	if _glance_t <= 0.0:
		_glance_t = randf_range(2.5, 5.0)
		_glance_target = randf_range(-0.22, 0.12)
	glance = lerpf(glance, _glance_target if spd < 0.3 else 0.0, 1.0 - exp(-dt * 3.0))
	# pozlar
	var p := _blank()
	var tot := 0.0
	for k: String in w:
		var wk: float = w[k]
		if wk < 0.002:
			continue
		var q: Dictionary
		match k:
			"loco": q = _loco(run_b)
			"air": q = _air()
			"push": q = _push(false)
			"pull": q = _push(true)
		for j: String in p:
			p[j] += q[j] * wk
		tot += wk
	for j: String in p:
		p[j] /= maxf(tot, 0.001)
	if state == "climb":
		p = _climb_pose()
	# sert/yumuşak iniş: çömelme
	var la := _ease(land_amt)
	if la > 0.0 and state != "climb":
		p["thigh.L"] += 0.75 * la
		p["thigh.R"] += 0.55 * la
		p["shin.L"] -= 1.35 * la
		p["shin.R"] -= 1.1 * la
		p["lean"] -= 0.32 * la
		p["upperarm.L"] += 0.35 * la
		p["head"] -= 0.15 * la
	if hard_t > 0.0 and state != "climb":   # sert iniş: elleri yere koyarak toparlanma
		var hk := _ease(minf(1.0, hard_t / 0.45))
		p["lean"] -= 0.55 * hk
		p["upperarm.L"] += 0.9 * hk
		p["upperarm.R"] += 0.7 * hk
		p["head"] += 0.25 * hk
	if state != "climb":
		p["lean"] += -_acc_s * 0.018
		p["chest"] += sin(t * lerpf(1.7, 4.8, exert)) * 0.035 * exert
		p["head"] += sin(t * lerpf(1.7, 4.8, exert) + 0.5) * 0.03 * exert
	if teeter > 0.0:   # kenarda: geriye yaslan, kollar savrulur, aşağı bak
		var tk := _ease(teeter)
		var sw := sin(t * 6.5)
		p["lean"] = lerpf(p["lean"], 0.12 + sw * 0.07, tk)
		p["upperarm.L"] = lerpf(p["upperarm.L"], 1.4 + sin(t * 5.2) * 0.7, tk)
		p["upperarm.R"] = lerpf(p["upperarm.R"], 1.1 + cos(t * 5.2) * 0.5, tk)
		p["forearm.L"] = lerpf(p["forearm.L"], 0.4, tk)
		p["head"] = lerpf(p["head"], -0.45, tk)
		p["thigh.L"] = lerpf(p["thigh.L"], 0.12, tk)
		p["thigh.R"] = lerpf(p["thigh.R"], -0.08, tk)
	# bakış: hedef öndeyse kafa ona çevrilir
	var want_look := 0.0
	if look_at != Vector3.INF and state != "climb":
		var hp := global_position + Vector3(0, 1.35, 0)
		var ldx := (look_at.x - hp.x) * face
		if ldx > 0.4:
			want_look = clampf(atan2(look_at.y - hp.y, ldx), -0.55, 0.6)
	_look = lerpf(_look, want_look, 1.0 - exp(-dt * 4.0))
	p["head"] += _look * 0.7
	p["neck"] += _look * 0.3
	if reach > 0.0:
		var r := _ease(reach)
		p["upperarm.L"] = lerpf(p["upperarm.L"], 2.55, r)
		p["forearm.L"] = lerpf(p["forearm.L"], 0.25, r)
		p["head"] = lerpf(p["head"], 0.45, r)
		p["neck"] = lerpf(p["neck"], 0.2, r)
		p["lean"] = lerpf(p["lean"], 0.08, r)
	# ayaklar: yerdeyken basan ayak zemine değsin (kalça yüksekliği bacak açılarından)
	var ground_w := 0.0 if state == "climb" else clampf(1.0 - w["air"], 0.0, 1.0)
	if ground_w > 0.0:
		var hl := THIGH * cos(p["thigh.L"]) + SHIN * cos(p["thigh.L"] + p["shin.L"])
		var hr := THIGH * cos(p["thigh.R"]) + SHIN * cos(p["thigh.R"] + p["shin.R"])
		var need := maxf(hl, hr) - LEG
		p["hy"] = lerpf(p["hy"], need + p["hy"] * 0.3, ground_w)
	hy_s = p["hy"]
	# ayak tabanı yere paralel (+ topuk/parmak hareketi zaten pozda)
	for s in ["L", "R"]:
		p["foot." + s] += -(p["thigh." + s] + p["shin." + s]) * ground_w * 0.85
	body.apply(p)
	_accessories(dt)

func _mocap_anim(dt: float, _run_b: float) -> void:
	var on_floor := is_on_floor() or state == "climb"
	var st := "loco"
	var sc := 1.0
	var xf := 0.2
	if caught:
		st = "death"
		xf = 0.15
	elif force_anim != "" and state == "cut" and absf(velocity.x) < 0.15:
		st = force_anim
		xf = 0.45
	elif wake_t > 0.0:
		st = "wake"
		sc = 0.55
	elif state == "dead":
		st = "air"
	elif state == "climb":
		st = "climb"
		sc = 0.67 / float(climb["dur"])
		xf = 0.1
	elif state == "air" or not on_floor:
		st = "air"
		xf = 0.15
	elif roll_t > 0.0:
		st = "roll"
		sc = 1.4
		xf = 0.1
	elif land_t > 0.0:
		st = "land"
		sc = 1.8
		xf = 0.08
	elif pushing or pulling:
		st = "push"
		sc = clampf(absf(velocity.x) / 0.23, 0.35, 3.2) * (-1.0 if pulling else 1.0)
	# bakış ve uzanma
	var want_look := 0.0
	if look_at != Vector3.INF and state != "climb":
		var hp := global_position + Vector3(0, 1.3, 0)
		var ldx := (look_at.x - hp.x) * face
		if ldx > 0.4:
			want_look = clampf(atan2(look_at.y - hp.y, ldx), -0.5, 0.6)
	_look = lerpf(_look, want_look, 1.0 - exp(-dt * 4.0))
	mocap.look_pitch = _look
	mocap.reach = _ease(reach)
	mocap.reach_target = look_at
	var hw := 0.0
	if st == "loco":
		hw = clampf(spd / 0.8, 0.0, 1.0) * lerpf(0.8, 0.35, clampf((spd - 3.4) / 2.0, 0.0, 1.0))
	mocap.hold = lerpf(mocap.hold, hw, 1.0 - exp(-dt * 6.0))
	mocap.hold_target = global_position + Vector3(face * 0.6, 0.72, 0.16)
	mocap.drive(st, spd, sc, dt, xf)

func _blank() -> Dictionary:
	var p := {}
	for j: String in NehirBody.JOINTS:
		p[j] = 0.0
	return p

func _loco(run_b: float) -> Dictionary:
	var p := _blank()
	var walk_b := clampf(spd / WALK, 0.0, 1.0)
	var ph := phase * TAU
	# bekleme: nefes, ağırlık aktarma, etrafa bakma
	var br := sin(t * 1.7)
	var idle := {"lean": -0.02 + br * 0.008, "spine": 0.0, "chest": br * 0.02, "neck": 0.0, "head": glance - 0.05,
		"thigh.L": 0.05 + sin(t * 0.45) * 0.02, "thigh.R": -0.03 - sin(t * 0.45) * 0.02, "shin.L": -0.1, "shin.R": -0.05,
		"foot.L": 0.0, "foot.R": 0.0, "upperarm.L": 0.06 + br * 0.01, "upperarm.R": 0.16, "forearm.L": 0.14, "forearm.R": 0.5,
		"hand.L": 0.05, "hand.R": -0.3, "hy": 0.0, "hx": sin(t * 0.45) * 0.012}
	# yürüme ve koşma döngüsü
	var amp := lerpf(0.4, 0.78, run_b)
	var knee := lerpf(0.72, 1.75, run_b)
	var arm := lerpf(0.3, 0.8, run_b)
	var cyc := {}
	cyc["lean"] = lerpf(-0.05, -0.24, run_b)
	cyc["spine"] = lerpf(0.0, -0.05, run_b)
	cyc["chest"] = sin(ph * 2.0) * 0.02
	cyc["neck"] = 0.0
	cyc["head"] = lerpf(0.02, 0.14, run_b)
	for s in ["L", "R"]:
		var f := ph + (0.0 if s == "L" else PI)
		var swing := maxf(0.0, cos(f + 0.25))
		cyc["thigh." + s] = amp * sin(f) + lerpf(0.0, 0.12, run_b)
		cyc["shin." + s] = -(lerpf(0.08, 0.25, run_b) + knee * pow(swing, 1.6))
		cyc["foot." + s] = 0.18 * sin(f) * (1.0 - run_b * 0.4) + 0.15 * swing - 0.25 * maxf(0.0, -sin(f)) * maxf(0.0, cos(f))
		var o := -sin(f)   # kol, aynı taraf bacağın tersi
		cyc["upperarm." + s] = arm * o + lerpf(0.02, 0.12, run_b)
		cyc["forearm." + s] = lerpf(0.22, 1.35, run_b) + maxf(0.0, o) * lerpf(0.2, 0.45, run_b)
		cyc["hand." + s] = 0.0
	# fener tutan sağ kol: daha az salınır, öne tutulur
	cyc["upperarm.R"] = cyc["upperarm.R"] * 0.35 + lerpf(0.14, 0.38, run_b)
	cyc["forearm.R"] = lerpf(0.5, 1.05, run_b)
	cyc["hand.R"] = -0.3
	cyc["hy"] = lerpf(0.0, 0.03, run_b) * maxf(0.0, sin(ph * 2.0))
	cyc["hx"] = 0.0
	for j: String in p:
		p[j] = lerpf(float(idle[j]), float(cyc[j]), walk_b)
	return p

func _air() -> Dictionary:
	var p := _blank()
	var up := clampf(velocity.y / JUMP_V, -1.0, 1.0)     # 1 = yükseliş, -1 = hızlı düşüş
	var rise := clampf(up, 0.0, 1.0)
	var fall := clampf(-up, 0.0, 1.0)
	var fl := sin(t * 11.0) * 0.12 * fall
	var mid := 1.0 - rise - fall
	p["lean"] = -0.12 * rise - 0.04 * mid + 0.05 * fall
	p["spine"] = -0.04
	p["head"] = 0.15 * rise - 0.18 * fall
	p["thigh.L"] = 0.95 * rise + 0.6 * mid + 0.35 * fall
	p["shin.L"] = -1.45 * rise - 1.0 * mid - 0.45 * fall
	p["thigh.R"] = 0.05 * rise + 0.2 * mid + 0.1 * fall
	p["shin.R"] = -0.55 * rise - 0.7 * mid - 0.3 * fall
	p["foot.L"] = 0.4 * rise
	p["foot.R"] = -0.2
	p["upperarm.L"] = 1.0 * rise + 0.7 * mid + (1.9 + fl) * fall
	p["forearm.L"] = 0.6 * rise + 0.4 * mid + 0.3 * fall
	p["upperarm.R"] = 0.9 * rise + 0.6 * mid + (1.5 - fl) * fall
	p["forearm.R"] = 0.9 * rise + 0.8 * mid + 0.4 * fall
	p["hand.R"] = -0.3
	return p

func _push(pull: bool) -> Dictionary:
	var p := _blank()
	var ph := phase * TAU
	var moving := clampf(spd / 0.6, 0.0, 1.0)
	p["lean"] = (0.26 if pull else -0.5)
	p["spine"] = 0.06 if pull else -0.08
	p["chest"] = 0.0
	p["head"] = (-0.1 if pull else 0.3)
	for s in ["L", "R"]:
		var f := ph + (0.0 if s == "L" else PI)
		var swing := maxf(0.0, cos(f + 0.25))
		var base := (0.25 if pull else -0.28)
		p["thigh." + s] = base + 0.3 * sin(f) * moving + (0.1 if s == "L" else -0.1) * (1.0 - moving)
		p["shin." + s] = -(0.25 + 0.75 * pow(swing, 1.5) * moving)
		p["foot." + s] = 0.1 * sin(f) * moving
		p["upperarm." + s] = (1.2 if pull else 1.38) + sin(f) * 0.04 * moving
		p["forearm." + s] = (0.15 if pull else 0.35)
		p["hand." + s] = 0.2
	p["hand.R"] = -0.1
	return p

func _climb_pose() -> Dictionary:
	var k: float = minf(1.0, climb["t"])
	var hang: bool = climb["hang"]
	var hp := {"lean": 0.04, "spine": 0.0, "chest": 0.0, "neck": 0.1, "head": 0.3, "thigh.L": 0.25, "thigh.R": 0.05, "shin.L": -0.35, "shin.R": -0.15,
		"foot.L": -0.3, "foot.R": -0.4, "upperarm.L": 2.95, "upperarm.R": 2.85, "forearm.L": 0.1, "forearm.R": 0.15, "hand.L": 0.2, "hand.R": 0.2, "hy": 0.0, "hx": 0.0}
	var pull := {"lean": -0.3, "spine": -0.1, "chest": 0.0, "neck": 0.0, "head": 0.15, "thigh.L": 0.95, "thigh.R": 0.15, "shin.L": -1.6, "shin.R": -0.45,
		"foot.L": 0.2, "foot.R": -0.3, "upperarm.L": 1.6, "upperarm.R": 1.5, "forearm.L": 1.7, "forearm.R": 1.6, "hand.L": 0.2, "hand.R": 0.2, "hy": 0.0, "hx": 0.0}
	var knee := {"lean": -0.65, "spine": -0.15, "chest": 0.0, "neck": 0.1, "head": 0.25, "thigh.L": 1.45, "thigh.R": -0.15, "shin.L": -2.2, "shin.R": -0.9,
		"foot.L": 0.4, "foot.R": -0.2, "upperarm.L": 0.45, "upperarm.R": 0.55, "forearm.L": 0.35, "forearm.R": 0.4, "hand.L": 0.6, "hand.R": 0.5, "hy": 0.0, "hx": 0.0}
	var stand := _loco(0.0)
	var keys: Array
	var ts: Array
	if hang:
		keys = [hp, hp, pull, knee, stand]
		ts = [0.0, 0.14, 0.55, 0.82, 1.0]
	else:
		keys = [pull, knee, stand]
		ts = [0.0, 0.5, 1.0]
	var out := _blank()
	for i in range(keys.size() - 1):
		if k <= ts[i + 1] or i == keys.size() - 2:
			var u := _ease((k - float(ts[i])) / maxf(0.001, float(ts[i + 1]) - float(ts[i])))
			for j: String in out:
				out[j] = lerpf(float(keys[i][j]), float(keys[i + 1][j]), u)
			break
	return out

# ---------------------------------------------------------------- aksesuarlar
func _mat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _build_lantern() -> void:
	lantern = Node3D.new()
	lantern.top_level = true
	add_child(lantern)
	var iron := _mat(Color(0.05, 0.05, 0.055), 0.6)
	iron.metallic = 0.5
	var parts := []
	# sap halkası, kapak, taban, kafes çubukları, cam
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.022
	tm.outer_radius = 0.03
	ring.mesh = tm
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, -0.02, 0)
	parts.append(ring)
	for spec in [[0.06, 0.03, -0.065], [0.05, 0.02, -0.08], [0.058, 0.025, -0.215]]:
		var cy := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = spec[0] * 0.8
		cm.bottom_radius = spec[0]
		cm.height = spec[1]
		cm.radial_segments = 12
		cy.mesh = cm
		cy.position = Vector3(0, spec[2], 0)
		parts.append(cy)
	for i in 4:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.008, 0.12, 0.008)
		bar.mesh = bm
		var ang := float(i) / 4.0 * TAU + PI / 4.0
		bar.position = Vector3(cos(ang) * 0.046, -0.145, sin(ang) * 0.046)
		parts.append(bar)
	for prt: MeshInstance3D in parts:
		prt.material_override = iron
		prt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lantern.add_child(prt)
	var glass := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.038
	gm.bottom_radius = 0.042
	gm.height = 0.11
	gm.radial_segments = 12
	glass.mesh = gm
	glass.position = Vector3(0, -0.145, 0)
	glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.62, 0.28)
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.55, 0.2)
	glass_mat.emission_energy_multiplier = 3.0
	glass.material_override = glass_mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lantern.add_child(glass)
	# sisin içinde fenerin etrafında yumuşak hale (kameraya dönük)
	halo = MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(1.1, 1.1)
	halo.mesh = hq
	var hs := Shader.new()
	hs.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled, cull_disabled;
uniform float k = 1.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float g = pow(max(0.0, 1.0 - r), 2.4);
	ALBEDO = vec3(1.0, 0.6, 0.28) * g * 0.32 * k;
}"""
	halo_mat = ShaderMaterial.new()
	halo_mat.shader = hs
	halo.material_override = halo_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0, -0.145, 0)
	lantern.add_child(halo)
	lamp_light = OmniLight3D.new()
	lamp_light.light_color = Color(1.0, 0.63, 0.32)
	lamp_light.light_energy = 1.7
	lamp_light.omni_range = 7.5
	lamp_light.omni_attenuation = 1.9
	lamp_light.shadow_enabled = true
	lamp_light.shadow_bias = 0.08
	lamp_light.position = Vector3(0, -0.12, 0.14)   # biraz kameraya doğru: vücudu yakmadan önünü aydınlatır
	lantern.add_child(lamp_light)

func _build_scarf() -> void:
	var knot := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.035
	tm.outer_radius = 0.07
	tm.rings = 16
	tm.ring_segments = 8
	knot.mesh = tm
	var red := _mat(Color(0.5, 0.045, 0.04), 0.85)
	red.rim_enabled = true
	red.rim = 0.4
	knot.material_override = red
	knot.top_level = true
	add_child(knot)
	scarf_knot = knot
	var mi := MeshInstance3D.new()
	scarf_mesh = ImmediateMesh.new()
	mi.mesh = scarf_mesh
	var rm := red.duplicate() as StandardMaterial3D
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = rm
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	for i in 8:
		scarf_pts.append(Vector3.ZERO)
		scarf_old.append(Vector3.ZERO)

func _build_braid() -> void:
	var hm := _mat(Color(0.06, 0.045, 0.04), 0.9)
	for i in 6:
		var b := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := lerpf(0.034, 0.02, float(i) / 5.0)
		sm.radius = r
		sm.height = r * 2.3
		sm.radial_segments = 10
		sm.rings = 6
		b.mesh = sm
		b.material_override = hm
		b.top_level = true
		add_child(b)
		braid_balls.append(b)
		braid_pts.append(Vector3.ZERO)
		braid_old.append(Vector3.ZERO)
	# örgü ucunda kırmızı kurdele
	var tie := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(0.03, 0.05, 0.03)
	tie.mesh = bx
	tie.material_override = _mat(Color(0.5, 0.045, 0.04))
	braid_balls[5].add_child(tie)
	tie.position = Vector3(0, -0.03, 0)

var _acc_init := false

func _accessories(dt: float) -> void:
	wind = 0.6 + 0.4 * sin(t * 0.7) + 0.3 * sin(t * 2.3)
	var fwd := Vector3(face, 0, 0)
	# --- fener: elden sarkan sarkaç
	var piv: Vector3 = body.bone_world("hand.R", Vector3(0, 0.1, 0) if mocap == null else Vector3.ZERO)
	if not _acc_init or piv.distance_to(_piv_prev) > 0.8:
		_piv_prev = piv
		_piv_vel = Vector3.ZERO
		lan_w = 0.0
	var vel := (piv - _piv_prev) / maxf(dt, 0.001)
	var acc := (vel - _piv_vel) / maxf(dt, 0.001)
	_piv_vel = vel
	_piv_prev = piv
	var L := 0.2
	var aa := -(9.8 / L) * sin(lan_th) - (clampf(acc.x, -40.0, 40.0) / L) * cos(lan_th) * 0.6 - lan_w * 3.2
	lan_w += aa * dt
	lan_th = clampf(lan_th + lan_w * dt, -1.2, 1.2)
	lantern.global_position = piv
	lantern.rotation = Vector3(0, 0, lan_th)
	var fl := 1.0 + 0.05 * sin(t * 13.0) + 0.04 * sin(t * 7.3 + 1.0) + 0.03 * sin(t * 23.0)
	lamp_light.light_energy = 1.7 * fl
	glass_mat.emission_energy_multiplier = 3.0 * fl
	halo_mat.set_shader_parameter("k", fl)
	# --- atkı: boyuna bağlı, rüzgârda arkaya uçuşan zincir
	var nt: Transform3D = body.bone_xform("neck")
	if mocap != null:   # mankenin boyun ekseni farklı: düğüm yatay halka
		nt = Transform3D(Basis(Vector3.UP, yaw), nt.origin + Vector3(0, 0.03, 0))
	scarf_knot.global_transform = Transform3D(nt.basis.orthonormalized(), nt * Vector3(0, 0.0, 0))
	scarf_knot.scale = Vector3(1.0, 0.75, 1.15)
	var anchor := nt * Vector3(0, 0.0, 0) - fwd * 0.06 + Vector3(0, -0.01, 0)
	_verlet(scarf_pts, scarf_old, anchor, 0.052, dt, Vector3(-velocity.x * 0.5 - face * 0.5 * wind, -7.0, 0.0), 0.93)
	scarf_mesh.clear_surfaces()
	scarf_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in scarf_pts.size():
		var a := scarf_pts[i]
		var nb := scarf_pts[mini(i + 1, scarf_pts.size() - 1)] - scarf_pts[maxi(i - 1, 0)]
		var d := Vector3(nb.x, nb.y, 0.0).normalized()
		var n := Vector3(-d.y, d.x, 0.0)
		var wd := lerpf(0.042, 0.03, float(i) / 7.0)
		var tw := sin(t * 5.0 + i * 0.7) * 0.02 * wind
		scarf_mesh.surface_set_normal(Vector3(0, 0, 1))
		scarf_mesh.surface_add_vertex(a + n * wd + Vector3(0, 0, 0.03 + tw))
		scarf_mesh.surface_set_normal(Vector3(0, 0, 1))
		scarf_mesh.surface_add_vertex(a - n * wd + Vector3(0, 0, 0.03 - tw))
	scarf_mesh.surface_end()
	# --- örgü: başın arkasından sarkan
	var hb: Transform3D = body.bone_xform("head")
	var banchor := hb * Vector3(0, 0.07, 0) - fwd * 0.09
	if mocap != null:
		banchor = hb.origin + Vector3(0, 0.03, 0) - fwd * 0.1
	_verlet(braid_pts, braid_old, banchor, 0.045, dt, Vector3(-velocity.x * 0.05 - face * 0.15 * wind, -9.0, 0.0), 0.94)
	for i in braid_pts.size():
		braid_balls[i].global_position = braid_pts[i] + Vector3(0, 0, -0.02)
	_acc_init = true

func _verlet(pts: Array[Vector3], old: Array[Vector3], anchor: Vector3, seg: float, dt: float, force: Vector3, damp: float) -> void:
	if not _acc_init or pts[0].distance_to(anchor) > 0.8:   # ilk kare ya da ışınlanma: zinciri yeniden diz
		for i in pts.size():
			pts[i] = anchor + Vector3(0, -seg * i, 0)
			old[i] = pts[i]
	pts[0] = anchor
	old[0] = anchor
	var dt2 := dt * dt
	for i in range(1, pts.size()):
		var cur := pts[i]
		var v := (cur - old[i]) * damp
		old[i] = cur
		pts[i] = cur + v + force * dt2
		pts[i].z = clampf(pts[i].z, -0.15, 0.15)
	for _it in 4:
		pts[0] = anchor
		for i in range(1, pts.size()):
			var d := pts[i] - pts[i - 1]
			var l := d.length()
			if l > 0.0001:
				var diff := (l - seg) / l
				if i == 1:
					pts[i] -= d * diff
				else:
					pts[i] -= d * diff * 0.5
					pts[i - 1] += d * diff * 0.5
		pts[0] = anchor
