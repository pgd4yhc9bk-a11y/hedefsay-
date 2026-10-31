class_name ModelRig extends Node2D
## 3D karakter modelini (glb) yandan ortografik bir kamerayla 2D oyuna yansıtır (2.5D).
## Model yoksa geçici bir 3D kukla gösterir. Düz siyah siluet: yalnızca imza parçalar (atkı, alev, tavşan) renkli kalır.
## Dosyalar: res://assets/3d/<karakter>/model.glb  ve  res://assets/3d/<karakter>/anim/<ad>.glb
## Bkz. MODEL-REHBERI.md

var who := "nehir"                 # klasör adı: nehir | cinar
var height_game := 54.0            # oyundaki boy (px)
var facing_yaw := 90.0             # modelin baktığı yön ayarı (derece): +Z'ye bakan model sağa döner
var silhouette := true

const VP := 256
const VIEW_H := 2.4
const CAM_Y := 1.15
const MODEL_H := 1.7
const ANIMS := ["idle", "walk", "run", "jump", "fall", "land", "roll", "push", "pull", "crawl", "climb", "slip", "wade", "cry", "hug"]
const LOOPING := ["idle", "walk", "run", "fall", "push", "pull", "crawl", "climb", "slip", "wade", "cry"]
const ACCENT := ["atki", "scarf", "alev", "flame", "tavsan", "bunny", "kurdele", "ribbon", "lantern_glow", "fener_cam"]

var vp: SubViewport
var spr: Sprite2D
var yaw: Node3D
var model: Node3D = null
var skel: Skeleton3D = null
var ap: AnimationPlayer = null
var has_model := false
var report := {}
var available: Array = []
var _cur := ""
var _ph := {}                       # geçici kukla parçaları
var _missing_bones := 0

func _ready() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(VP, VP)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = VIEW_H
	cam.position = Vector3(0.0, CAM_Y, 6.0)
	cam.near = 0.1
	cam.far = 30.0
	vp.add_child(cam)
	yaw = Node3D.new()
	yaw.rotation.y = deg_to_rad(facing_yaw)
	vp.add_child(yaw)
	_load_model()
	if not has_model:
		_build_placeholder()
	spr = Sprite2D.new()
	spr.texture = vp.get_texture()
	spr.centered = false
	var gs := (height_game / MODEL_H) * VIEW_H / float(VP)
	spr.scale = Vector2(gs, gs)
	spr.offset = Vector2(-VP / 2.0, -(CAM_Y + VIEW_H / 2.0) / VIEW_H * VP)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(spr)

# ---------- model yükleme ----------
func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null

func _meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_meshes(c, out)

func _res_path(base: String) -> String:   # .glb ya da .fbx (Mixamo .fbx verir)
	for ext: String in [".glb", ".fbx", ".gltf"]:
		if ResourceLoader.exists(base + ext):
			return base + ext
	return ""

func _load_model() -> void:
	var path := _res_path("res://assets/3d/%s/model" % who)
	report = {"model": "yok (geçici kukla gösteriliyor)", "kemik": 0, "boy_ham": 0.0, "olcek": 1.0, "animasyonlar": [], "eksik_animasyon": [], "eksik_kemik": 0, "parca": 0}
	if path == "":
		report["eksik_animasyon"] = ANIMS.duplicate()
		return
	var ps := load(path) as PackedScene
	if ps == null:
		report["model"] = "yüklenemedi"
		return
	model = ps.instantiate() as Node3D
	yaw.add_child(model)
	has_model = true
	report["model"] = "yüklendi"
	skel = _find(model, "Skeleton3D") as Skeleton3D
	var meshes: Array = []
	_meshes(model, meshes)
	report["parca"] = meshes.size()
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in meshes:
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var h := maxf(0.001, box.size.y)
	var s := (MODEL_H * height_game / 54.0) / h
	model.scale = Vector3.ONE * s
	model.position = Vector3(-box.get_center().x * s, -box.position.y * s, -box.get_center().z * s)
	report["boy_ham"] = snappedf(h, 0.01)
	report["olcek"] = snappedf(s, 0.001)
	if skel != null:
		report["kemik"] = skel.get_bone_count()
	if silhouette:
		_silhouette(meshes)
	ap = AnimationPlayer.new()
	model.add_child(ap)
	_load_anims()

func _silhouette(meshes: Array) -> void:
	var black := StandardMaterial3D.new()
	black.albedo_color = Color("#0b0b0c")
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mi: MeshInstance3D in meshes:
		for i in mi.get_surface_override_material_count():
			var m := mi.get_active_material(i)
			var nm := ""
			if m != null:
				nm = String(m.resource_name).to_lower()
			var accent := false
			for a: String in ACCENT:
				if nm.contains(a):
					accent = true
			if accent and m is BaseMaterial3D:
				var keep := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				keep.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mi.set_surface_override_material(i, keep)
			else:
				mi.set_surface_override_material(i, black)

func _bone_for(name: String) -> String:
	if skel == null:
		return ""
	if skel.find_bone(name) >= 0:
		return name
	var alt := name.replace(":", "_")
	if skel.find_bone(alt) >= 0:
		return alt
	var stripped := name.get_slice(":", name.get_slice_count(":") - 1) if name.contains(":") else name
	for cand: String in [stripped, "mixamorig_" + stripped, "mixamorig:" + stripped]:
		if skel.find_bone(cand) >= 0:
			return cand
	return ""

func _retarget(a: Animation) -> void:
	for ti in range(a.get_track_count() - 1, -1, -1):
		var t := a.track_get_type(ti)
		if t != Animation.TYPE_POSITION_3D and t != Animation.TYPE_ROTATION_3D and t != Animation.TYPE_SCALE_3D:
			continue
		var sub := a.track_get_path(ti).get_concatenated_subnames()
		if sub == "" or skel == null:
			a.remove_track(ti)
			continue
		var bone := _bone_for(sub)
		if bone == "":
			_missing_bones += 1
			a.remove_track(ti)
			continue
		a.track_set_path(ti, NodePath(str(model.get_path_to(skel)) + ":" + bone))

func _add_anim(lib: AnimationLibrary, key: String, a: Animation) -> void:
	if lib.has_animation(key):
		return
	var c := a.duplicate() as Animation
	_retarget(c)
	c.loop_mode = Animation.LOOP_LINEAR if key in LOOPING else Animation.LOOP_NONE
	lib.add_animation(key, c)

func _load_anims() -> void:
	var lib := AnimationLibrary.new()
	for n: String in ANIMS:
		var path := _res_path("res://assets/3d/%s/anim/%s" % [who, n])
		if path == "":
			continue
		var ps := load(path) as PackedScene
		if ps == null:
			continue
		var inst := ps.instantiate()
		var src := _find(inst, "AnimationPlayer") as AnimationPlayer
		if src != null:
			for an: String in src.get_animation_list():
				if an != "RESET":
					_add_anim(lib, n, src.get_animation(an))
					break
		inst.free()
	var own := _find(model, "AnimationPlayer") as AnimationPlayer   # modelin içinde gömülü animasyonlar da kullanılabilir
	if own != null and own != ap:
		for an: String in own.get_animation_list():
			for n: String in ANIMS:
				if an.to_lower().contains(n):
					_add_anim(lib, n, own.get_animation(an))
	ap.add_animation_library("", lib)
	for n: String in ANIMS:
		if lib.has_animation(n):
			available.append(n)
	report["animasyonlar"] = available.duplicate()
	var miss: Array = []
	for n: String in ["idle", "walk", "run", "jump", "fall", "land"]:
		if not available.has(n):
			miss.append(n)
	report["eksik_animasyon"] = miss
	report["eksik_kemik"] = _missing_bones

func report_text() -> String:
	var s := "3D MODEL (%s): %s\n" % [who, report["model"]]
	if has_model:
		s += "kemik: %s  parça: %s  ham boy: %s m  ölçek: %s\n" % [report["kemik"], report["parca"], report["boy_ham"], report["olcek"]]
	s += "animasyon: %s\n" % [", ".join(PackedStringArray(report["animasyonlar"]))]
	if not (report["eksik_animasyon"] as Array).is_empty():
		s += "EKSİK animasyon: %s\n" % [", ".join(PackedStringArray(report["eksik_animasyon"]))]
	if int(report["eksik_kemik"]) > 0:
		s += "uyuşmayan kemik izi: %s\n" % report["eksik_kemik"]
	return s

# ---------- geçici kukla ----------
func _limb(parent: Node3D, pos: Vector3, length: float, radius: float, col: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = length + radius * 2.0
	mi.mesh = cm
	mi.position = Vector3(0, -length / 2.0, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	pivot.add_child(mi)
	return pivot

func _build_placeholder() -> void:
	var k := Color("#0b0b0c")
	var root := Node3D.new()
	root.scale = Vector3.ONE * (height_game / 54.0)
	yaw.add_child(root)
	var hips := Node3D.new()
	hips.position = Vector3(0, 0.82, 0)
	root.add_child(hips)
	_ph["hips"] = hips
	var torso := _limb(hips, Vector3.ZERO, -0.5, 0.15, k)   # yukarı doğru uzanır
	_ph["torso"] = torso
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.26
	head.mesh = sm
	head.position = Vector3(0.0, 0.72, 0.0)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = k
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	head.material_override = hm
	hips.add_child(head)
	# göz
	var eye := MeshInstance3D.new()
	var es := SphereMesh.new()
	es.radius = 0.025
	es.height = 0.05
	eye.mesh = es
	eye.position = Vector3(0.12, 0.74, 0.04)
	var em := StandardMaterial3D.new()
	em.albedo_color = Color.WHITE
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye.material_override = em
	hips.add_child(eye)
	# atkı (imza renk)
	var sc := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.07, 0.2)
	sc.mesh = box
	sc.position = Vector3(-0.2, 0.56, 0.0)
	var scm := StandardMaterial3D.new()
	scm.albedo_color = Color("#c0392b")
	scm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sc.material_override = scm
	hips.add_child(sc)
	_ph["thigh_f"] = _limb(hips, Vector3(0, 0, 0.06), 0.4, 0.07, k)
	_ph["thigh_b"] = _limb(hips, Vector3(0, 0, -0.06), 0.4, 0.07, k)
	_ph["shin_f"] = _limb(_ph["thigh_f"], Vector3(0, -0.4, 0), 0.4, 0.06, k)
	_ph["shin_b"] = _limb(_ph["thigh_b"], Vector3(0, -0.4, 0), 0.4, 0.06, k)
	_ph["arm_f"] = _limb(hips, Vector3(0, 0.5, 0.12), 0.32, 0.05, k)
	_ph["arm_b"] = _limb(hips, Vector3(0, 0.5, -0.12), 0.32, 0.05, k)
	_ph["fore_f"] = _limb(_ph["arm_f"], Vector3(0, -0.32, 0), 0.28, 0.045, k)
	_ph["fore_b"] = _limb(_ph["arm_b"], Vector3(0, -0.32, 0), 0.28, 0.045, k)
	# fener (imza renk)
	var lamp := MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.07
	ls.height = 0.14
	lamp.mesh = ls
	lamp.position = Vector3(0, -0.3, 0)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color("#ff8a1f")
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp.material_override = lm
	_ph["fore_f"].add_child(lamp)

func _rz(n: String, a: float) -> void:
	(_ph[n] as Node3D).rotation.z = a

func _pose_placeholder(state: String, p: Player, t: float) -> void:
	var ph := p.anim * PI
	var hips: Node3D = _ph["hips"]
	hips.position.y = 0.82
	hips.rotation.z = 0.0
	match state:
		"run", "walk":
			var sw := 0.9 if state == "run" else 0.55
			_rz("thigh_f", sin(ph) * sw)
			_rz("thigh_b", -sin(ph) * sw)
			_rz("shin_f", -maxf(0.0, cos(ph)) * 1.0 - 0.1)
			_rz("shin_b", -maxf(0.0, -cos(ph)) * 1.0 - 0.1)
			_rz("arm_f", -sin(ph) * sw * 0.9)
			_rz("arm_b", sin(ph) * sw * 0.9)
			_rz("fore_f", 0.5)
			_rz("fore_b", 0.5)
			hips.position.y = 0.82 - absf(sin(ph)) * 0.04
			hips.rotation.z = -0.12 if state == "run" else -0.05
		"jump":
			_rz("thigh_f", 0.9)
			_rz("shin_f", -1.2)
			_rz("thigh_b", -0.3)
			_rz("shin_b", -0.6)
			_rz("arm_f", 2.4)
			_rz("arm_b", 2.0)
			_rz("fore_f", 0.3)
			_rz("fore_b", 0.3)
		"fall":
			var f := sin(t * 14.0)
			_rz("thigh_f", 0.6 + f * 0.5)
			_rz("thigh_b", -0.5 - f * 0.5)
			_rz("shin_f", -0.9)
			_rz("shin_b", -0.9)
			_rz("arm_f", 2.3 + f * 0.5)
			_rz("arm_b", -2.0 - f * 0.5)
			hips.rotation.z = -0.15
		"land":
			hips.position.y = 0.62
			_rz("thigh_f", 1.0)
			_rz("thigh_b", 0.7)
			_rz("shin_f", -1.7)
			_rz("shin_b", -1.5)
			_rz("arm_f", 0.8)
			_rz("arm_b", 0.4)
			hips.rotation.z = -0.35
		"push", "pull":
			var lean := -0.28 if state == "push" else 0.25
			hips.rotation.z = lean
			_rz("thigh_f", 0.3 + sin(ph) * 0.25)
			_rz("thigh_b", -0.3 - sin(ph) * 0.25)
			_rz("shin_f", -0.3)
			_rz("shin_b", -0.2)
			_rz("arm_f", 1.5)
			_rz("arm_b", 1.4)
			_rz("fore_f", 0.05)
			_rz("fore_b", 0.05)
		_:
			var br := sin(t * 1.8)
			_rz("thigh_f", 0.05)
			_rz("thigh_b", -0.05)
			_rz("shin_f", -0.05)
			_rz("shin_b", -0.05)
			_rz("arm_f", 0.1 + br * 0.03)
			_rz("arm_b", -0.1)
			_rz("fore_f", 0.2)
			_rz("fore_b", 0.2)
			hips.position.y = 0.82 + br * 0.006

# ---------- durum seçimi ve oynatma ----------
func _state(p: Player) -> Array:   # [animasyon adı, hız çarpanı]
	var spd := absf(p.velocity.x)
	if not p.is_on_floor():
		if p.velocity.y < 0.0:
			return ["jump", 1.0]
		if p.fall_t > 0.12 and p.velocity.y > 260.0:
			return ["fall", 1.0]
		return ["jump", 0.0]   # tepe noktası: son karede bekle
	if p.recover > 0.5:
		return ["roll", 1.0]
	if p.recover > 0.0 or p.squash > 0.0:
		return ["land", 1.0]
	if p.grab:
		var moving_toward := p.velocity.x * p.face > 0.0
		return ["push" if moving_toward else "pull", clampf(spd / 85.0, 0.0, 1.5)]
	if p.on_ice and spd > 25.0:
		return ["slip", 1.0]
	if p.mud > 0 and spd > 20.0:
		return ["wade", clampf(spd / 90.0, 0.4, 1.4)]
	if spd > 20.0:
		if spd >= 130.0:
			return ["run", clampf(spd / 165.0, 0.5, 1.4)]   # adım hızı yürüme hızına bağlı: ayak kaymasını azaltır
		return ["walk", clampf(spd / 100.0, 0.5, 1.4)]
	return ["idle", 1.0]

const FALLBACK := {"run": "walk", "walk": "run", "roll": "land", "land": "idle", "pull": "push", "push": "walk", "slip": "walk", "wade": "walk", "fall": "jump", "crawl": "walk"}

func update_pose(p: Player, t: float) -> void:
	var st := _state(p)
	var name: String = st[0]
	spr.scale.x = absf(spr.scale.x) * float(p.face)
	var sqk := 1.0 - p.squash * 0.6 if p.squash > 0.0 else 1.0
	spr.scale.y = absf(spr.scale.x) * sqk
	if has_model and ap != null:
		var use := name
		var guard := 0
		while not available.has(use) and FALLBACK.has(use) and guard < 4:
			use = FALLBACK[use]
			guard += 1
		if available.has(use):
			if ap.current_animation != use:
				ap.play(use, 0.15)
			ap.speed_scale = float(st[1]) if float(st[1]) > 0.0 else 0.0
			_cur = use
		return
	_pose_placeholder(name, p, t)
	_cur = name

func hand_world(p: Player) -> Vector2:
	return p.global_position + Vector2(p.face * 14.0, -26.0)

func ember_world(p: Player) -> Vector2:
	return p.global_position + Vector2(0, -30)
