class_name NehirMocap extends Node3D
## Nehir'in mocap gövdesi: Quaternius kadın mankeni (CC0) + Universal Animation Library animasyonları (CC0).
## AnimationTree kodla kurulur: hız karışımı (bekle/yürü/koş/depar) + durum geçişleri (hava, iniş, yuvarlanma, itme,
## tırmanma, uyanma, yakalanma). Animasyondan sonra kodla ek: başla bakış, kolla kurdeleye uzanma.
## Boy: 1.45 m (manken 1.75 m -> 0.83).

var SCALE := 0.83
var meshy := false             # Meshy modeli (kendi dokusu, saçı, atkısı) kullanılıyor mu
var head_bone := "Head"
var run_nat := 3.55            # koşu karışımının ölçülen doğal hızı (modele göre)
var head_fix := 0.0            # Meshy modelinde baş öne eğik duruyor: yukarı düzeltme (radyan)
var push_back := 0.17          # iterken gövdenin geri alınacağı mesafe (eller kasa yüzeyinde)
var anim_lib := "res://proto/mocap/anim.res"
const STATES := ["loco", "air", "land", "roll", "push", "climb", "wake", "death", "reach", "crouch", "torch", "any", "pickup", "hug"]
var who := "nehir"              # nehir | cinar
var height := 1.45
var bone_aliases := {}          # UAL adı -> bu modeldeki kemik adı (kol, baş, ayak)
# isimsiz arayüz adları -> manken kemikleri (fener, atkı, örgü bağlantısı için)
var MAP := {"neck": "neck_01", "head": "Head", "hand.R": "middle_01_r", "hand.L": "middle_01_l"}

var model: Node3D
var skel: Skeleton3D
var tree: AnimationTree
var mesh: MeshInstance3D
var state := "loco"
var look_pitch := 0.0          # + yukarı (radyan)
var reach := 0.0               # 0..1: sol kol yukarı uzanır
var reach_target := Vector3.INF
var hold := 0.0                # 0..1: fener kolunu öne-aşağı tut (bacağa çarpmasın)
var hold_target := Vector3.INF
var grip_r := 1.9               # sağ el kapanma açısı (radyan): fener sapını kavrar
var grip_l := 0.45
signal footstep(strength: float)   # ayak yere bastığında (animasyondan)
var _foot_down := {}
var _bi := {}

func _ready() -> void:
	if who == "cinar":   # Meshy ile üretilen Çınar (Mixamo iskeleti), 6 yaş: 1.15 m
		meshy = true
		model = (load("res://proto/mocap/cinar_meshy.glb") as PackedScene).instantiate()
		SCALE = height / 1.70
		head_bone = "mixamorig_Head"
		anim_lib = "res://proto/mocap/anim_cinar.res"
		MAP = {"neck": "mixamorig_Neck", "head": "mixamorig_Head", "hand.R": "mixamorig_RightHand", "hand.L": "mixamorig_LeftHand"}
		bone_aliases = {"neck_01": "mixamorig_Neck", "upperarm_l": "mixamorig_LeftArm", "lowerarm_l": "mixamorig_LeftForeArm", "hand_l": "mixamorig_LeftHand",
			"upperarm_r": "mixamorig_RightArm", "lowerarm_r": "mixamorig_RightForeArm", "hand_r": "mixamorig_RightHand",
			"ball_l": "mixamorig_LeftToeBase", "ball_r": "mixamorig_RightToeBase"}
		run_nat = 2.85
		head_fix = 0.0
		push_back = 0.0
	meshy = meshy or (ResourceLoader.exists("res://proto/mocap/nehir_meshy.glb") and ResourceLoader.exists("res://proto/mocap/anim_nehir.res"))
	if who == "cinar":
		pass
	elif meshy:   # Meshy ile üretilen Nehir (1.70 m) + ona aktarılmış animasyonlar
		model = (load("res://proto/mocap/nehir_meshy.glb") as PackedScene).instantiate()
		SCALE = 1.45 / 1.70
		head_bone = "head"
		anim_lib = "res://proto/mocap/anim_nehir.res"
		MAP = {"neck": "neck_01", "head": "head", "hand.R": "hand_r", "hand.L": "hand_l"}
		run_nat = 2.85
		push_back = -0.05
		head_fix = 0.32
	else:
		model = (load("res://proto/mocap/manken_kiz.glb") as PackedScene).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * SCALE
	model.rotation.y = PI / 2.0      # model +Z'ye bakar; gövde +X'e baksın
	skel = model.find_child("Skeleton3D", true, false)
	mesh = model.find_child("Mannequin_F", true, false) if not meshy else _first_mesh(skel)
	for i in skel.get_bone_count():
		_bi[skel.get_bone_name(i)] = i
	for k: String in bone_aliases:   # UAL adıyla da bulunsun
		if _bi.has(bone_aliases[k]):
			_bi[k] = _bi[bone_aliases[k]]
	_foot_down = {"ball_l": true, "ball_r": true}
	var oldap := model.find_child("AnimationPlayer", true, false)
	if oldap != null:
		oldap.queue_free()   # modelin kendi oynatıcısı değil, bizim ağacımız sürer
	if not meshy:
		_style()
		_hair()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 2   # karakter katmanı: fenerin güçlü ışığı vurmaz, yumuşak gövde ışığı vurur
		if meshy:   # Meshy dokusunun parlaklık haritası elleri/yüzü ayna gibi yapıyor: mat kumaş ve ten
			var m3 := mi as MeshInstance3D
			for si in m3.mesh.get_surface_count():
				var base := m3.get_active_material(si)
				if base is StandardMaterial3D:
					var mt := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
					mt.metallic = 0.0
					mt.metallic_texture = null
					mt.roughness = 0.92
					mt.roughness_texture = null
					mt.metallic_specular = 0.15
					mt.albedo_color = Color(0.8, 0.77, 0.75)
					mt.vertex_color_use_as_albedo = true   # eller köşe rengiyle koyulaştırıldı
					m3.set_surface_override_material(si, mt)
	_build_tree()

func _first_mesh(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D:
			return c
	return null

func _style() -> void:
	var main := StandardMaterial3D.new()     # koyu yün palto / kumaş
	main.albedo_color = Color(0.06, 0.058, 0.066)
	main.roughness = 1.0
	main.metallic_specular = 0.1
	main.rim_enabled = true
	main.rim = 0.12
	main.rim_tint = 0.7
	var joint := main.duplicate() as StandardMaterial3D
	joint.albedo_color = Color(0.05, 0.05, 0.055)
	for s in mesh.mesh.get_surface_count():
		var nm := mesh.mesh.surface_get_material(s).resource_name if mesh.mesh.surface_get_material(s) != null else ""
		mesh.set_surface_override_material(s, joint if nm == "M_Joints" else main)

func _hair() -> void:   # manken kel: başa koyu saç kabuğu (kafa kemiğini izler)
	var ba := BoneAttachment3D.new()
	ba.bone_name = "Head"
	skel.add_child(ba)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.035, 0.028, 0.025)
	hm.roughness = 0.85
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.112
	sm.height = 0.21
	cap.mesh = sm
	cap.material_override = hm
	cap.position = Vector3(0, 0.115, -0.022)
	cap.scale = Vector3(0.97, 1.0, 1.04)
	ba.add_child(cap)
	var bun := MeshInstance3D.new()   # ense: örgünün başladığı topuz
	var bs := SphereMesh.new()
	bs.radius = 0.05
	bs.height = 0.09
	bun.mesh = bs
	bun.material_override = hm
	bun.position = Vector3(0, 0.06, -0.1)
	ba.add_child(bun)

func _anim(n: String) -> AnimationNodeAnimation:
	var a := AnimationNodeAnimation.new()
	a.animation = n
	return a

func _build_tree() -> void:
	tree = AnimationTree.new()
	tree.add_animation_library("", load(anim_lib))
	model.add_child(tree)
	tree.root_node = NodePath("..")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var bt := AnimationNodeBlendTree.new()
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = 8.0
	loco.sync = true
	# noktalar animasyonların ölçülen doğal hızında (1.45 m boyda): ayak kaymaz
	loco.add_blend_point(_anim("Idle_Lantern"), 0.0)
	loco.add_blend_point(_anim("Walk"), 0.77)
	loco.add_blend_point(_anim("Jog_Fwd"), 4.9)
	loco.add_blend_point(_anim("Sprint"), 7.3)
	bt.add_node("loco_bs", loco)
	var lts := AnimationNodeTimeScale.new()
	bt.add_node("loco", lts)
	bt.connect_node("loco", 0, "loco_bs")
	var nodes := {
		"air": _anim("Jump"), "land": _anim("Jump_Land"), "roll": _anim("Roll"), "push": _anim("Push"),
		"any": _anim("Idle"), "climb": _anim("ClimbUp_1m"), "wake": _anim("LayToIdle"), "death": _anim("Death01"), "reach": _anim("Idle_Lantern"), "crouch": _anim("Crouch_Idle"), "torch": _anim("Idle_Torch"), "hug": _anim("M_Hug" if ResourceLoader.exists(anim_lib) and (load(anim_lib) as AnimationLibrary).has_animation("M_Hug") else "Crouch_Idle"), "pickup": _anim("M_Pick_Up" if who == "nehir" and ResourceLoader.exists(anim_lib) and (load(anim_lib) as AnimationLibrary).has_animation("M_Pick_Up") else "Crouch_Idle"),
	}
	for k: String in nodes:
		bt.add_node(k + "_a", nodes[k])
		var ts := AnimationNodeTimeScale.new()
		bt.add_node(k, ts)
		bt.connect_node(k, 0, k + "_a")
	var tr := AnimationNodeTransition.new()
	tr.xfade_time = 0.2
	tr.input_count = STATES.size()
	for i in STATES.size():
		tr.set_input_name(i, STATES[i])
		tr.set_input_reset(i, true)
	bt.add_node("state", tr)
	for i in STATES.size():
		bt.connect_node("state", i, STATES[i])
	bt.connect_node("output", 0, "state")
	tree.tree_root = bt
	tree.active = true
	for k: String in nodes:
		tree.set("parameters/%s/scale" % k, 1.0)
	tree.set("parameters/loco/scale", 1.0)

## Herhangi bir animasyonu (ör. Meshy'den gelen M_...) "any" durumunda oynat. Aynı ad tekrar istenirse baştan başlamaz.
var any_name := ""
func set_any(anim_name: String) -> void:
	if anim_name == any_name:
		return
	any_name = anim_name
	var node := (tree.tree_root as AnimationNodeBlendTree).get_node("any_a") as AnimationNodeAnimation
	node.animation = anim_name
	if state == "any":   # zaten bu durumdaysak geçişi yeniden başlat
		state = ""

func has_anim(anim_name: String) -> bool:
	return tree.has_animation(anim_name)

## Her kare: durum, hız ve zaman ölçeği; sonra animasyonu ilerlet ve kodla eklemeleri uygula.
func drive(st: String, speed: float, scale: float, dt: float, xfade := 0.2) -> void:
	if st != "any":
		any_name = "" if st != state else any_name
	if st != state:
		state = st
		(tree.tree_root as AnimationNodeBlendTree).get_node("state").xfade_time = xfade
		tree.set("parameters/state/transition_request", st)
	if st == "loco":
		# koşu: yürüme ile karışık koşu pozu (daha kısa adım) + tam hıza göre yavaşlatılmış oynatma
		# yürüme ve koşu farklı adım ritminde: karıştırmak ayakları kaydırır. Bunun yerine yürüme hızlandırılır,
		# 1.3-1.7 m/s arasında kısa bir geçişle koşuya (koşu + %22 yürüme karışık poz, ölçülen doğal hız 3.55) geçilir.
		var p := speed
		var sc := 1.0
		if speed > 0.77 and speed <= 1.3:
			p = 0.77
			sc = speed / 0.77
		elif speed > 1.3 and speed < 1.7:
			var k := (speed - 1.3) / 0.4
			p = lerpf(0.77, 4.0, k)
			sc = lerpf(1.3 / 0.77, 1.7 / run_nat, k)
		elif speed >= 1.7:
			p = 4.0
			sc = speed / run_nat
		tree.set("parameters/loco_bs/blend_position", p)
		tree.set("parameters/loco/scale", sc)
	else:
		tree.set("parameters/%s/scale" % st, scale)
	tree.advance(dt)
	_post()
	if st == "loco" or st == "push" or st == "land":
		_feet(speed)

func _feet(speed: float) -> void:   # ayak yüksekliği eşiği geçince adım sesi
	if speed < 0.15 and state == "loco":
		return
	for b: String in _foot_down:
		var y := (skel.get_bone_global_pose(_bi[b]).origin.y) * SCALE
		var down: bool = _foot_down[b]
		if down and y > 0.07:
			_foot_down[b] = false
		elif not down and y < 0.035:
			_foot_down[b] = true
			footstep.emit(clampf(speed / 3.4, 0.0, 1.0))

func _post() -> void:
	# bakış: kafayı yan eksende (iskelet X) çevir
	var lp := look_pitch + (head_fix if state in ["loco", "air", "land"] else 0.0)
	if absf(lp) > 0.001:
		_rot_global(head_bone, Vector3(1, 0, 0), -lp * 0.7)
		_rot_global(MAP["neck"], Vector3(1, 0, 0), -lp * 0.3)
	if hold > 0.001 and hold_target != Vector3.INF:
		_aim("upperarm_r", "lowerarm_r", hold_target, hold * 0.65)
		_aim("lowerarm_r", "hand_r", hold_target, hold * 0.8)
	# kurdeleye uzanma: sol kolu hedefe doğru çevir
	# eller: eklenen parmak kemiği avuca doğru kıvrılır (sağ el feneri kavrar, sol el yarı açık)
	_curl("fingers_r", "hand_r", "RightHand_End", Vector3(1, 0, 0), grip_r)
	_curl("fingers_l", "hand_l", "LeftHand_End", Vector3(-1, 0, 0), grip_l * (1.0 - reach))
	var front := reach_target != Vector3.INF and (reach_target.x - global_position.x) * signf(global_transform.basis.x.x) > 0.2
	if reach > 0.001 and front:
		_aim("upperarm_l", "lowerarm_l", reach_target, reach)
		_aim("lowerarm_l", "hand_l", reach_target, reach)

## Parmak kemiğini avuca doğru kıvır. Eksen dinlenme pozundan (el yönü x avuç yönü) hesaplanır, el ile birlikte döner.
func _curl(fb: String, hb: String, eb: String, palm: Vector3, ang: float) -> void:
	if not _bi.has(fb) or not _bi.has(hb) or not _bi.has(eb) or absf(ang) < 0.01:
		return
	var hr := skel.get_bone_global_rest(_bi[hb])
	var d := (skel.get_bone_global_rest(_bi[eb]).origin - hr.origin).normalized()
	var axis_rest := d.cross(palm).normalized()
	var local_axis := hr.basis.orthonormalized().inverse() * axis_rest
	var hp := skel.get_bone_global_pose(_bi[hb]).basis.orthonormalized()
	_rot_global(fb, (hp * local_axis).normalized(), ang)

func _rot_global(bn: String, axis: Vector3, ang: float) -> void:
	var i: int = _bi[bn]
	var par := skel.get_bone_parent(i)
	var g := skel.get_bone_global_pose(i)
	var ng := Basis(axis, ang) * g.basis
	var pb := skel.get_bone_global_pose(par).basis if par >= 0 else Basis()
	skel.set_bone_pose_rotation(i, (pb.inverse() * ng).get_rotation_quaternion())

func _aim(bn: String, child: String, target_world: Vector3, wgt: float) -> void:
	var i: int = _bi[bn]
	var c: int = _bi[child]
	var inv := skel.global_transform.affine_inverse()
	var tgt := inv * target_world
	var g := skel.get_bone_global_pose(i)
	var cur := (skel.get_bone_global_pose(c).origin - g.origin).normalized()
	var want := (tgt - g.origin).normalized()
	if cur.length() < 0.5 or want.length() < 0.5:
		return
	var q := Quaternion(cur, want).slerp(Quaternion(), 1.0 - wgt)
	var ng := Basis(q) * g.basis
	var par := skel.get_bone_parent(i)
	var pb := skel.get_bone_global_pose(par).basis if par >= 0 else Basis()
	skel.set_bone_pose_rotation(i, (pb.inverse() * ng).get_rotation_quaternion())
	skel.force_update_bone_child_transform(i)

const GRIP := {"hand.R": ["RightHand_End", "mixamorig_RightHandMiddle1"], "hand.L": ["LeftHand_End", "mixamorig_LeftHandMiddle1"]}

func bone_world(n: String, local_off := Vector3.ZERO) -> Vector3:
	var bn: String = MAP.get(n, n)
	if meshy and GRIP.has(n):   # avucun ortası (fener sapı burada tutulur)
		var hw := skel.global_transform * skel.get_bone_global_pose(_bi[bn]).origin
		for e: String in GRIP[n]:
			if _bi.has(e):
				var ew := skel.global_transform * skel.get_bone_global_pose(_bi[e]).origin
				var k := 0.55 if e.ends_with("_End") else 0.85
				return hw.lerp(ew, k) + Vector3(0, -0.015, 0)
		return hw
	return (skel.global_transform * skel.get_bone_global_pose(_bi[bn])) * (local_off / SCALE)

func bone_xform(n: String) -> Transform3D:
	var bn: String = MAP.get(n, n)
	return skel.global_transform * skel.get_bone_global_pose(_bi[bn])
