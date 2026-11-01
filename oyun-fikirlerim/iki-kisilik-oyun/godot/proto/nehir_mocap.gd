class_name NehirMocap extends Node3D
## Nehir'in mocap gövdesi: Quaternius kadın mankeni (CC0) + Universal Animation Library animasyonları (CC0).
## AnimationTree kodla kurulur: hız karışımı (bekle/yürü/koş/depar) + durum geçişleri (hava, iniş, yuvarlanma, itme,
## tırmanma, uyanma, yakalanma). Animasyondan sonra kodla ek: başla bakış, kolla kurdeleye uzanma.
## Boy: 1.45 m (manken 1.75 m -> 0.83).

const SCALE := 0.83
const STATES := ["loco", "air", "land", "roll", "push", "climb", "wake", "death", "reach"]
# isimsiz arayüz adları -> manken kemikleri (fener, atkı, örgü bağlantısı için)
const MAP := {"neck": "neck_01", "head": "Head", "hand.R": "middle_01_r", "hand.L": "middle_01_l"}

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
signal footstep(strength: float)   # ayak yere bastığında (animasyondan)
var _foot_down := {"ball_l": true, "ball_r": true}
var _bi := {}

func _ready() -> void:
	model = (load("res://proto/mocap/manken_kiz.glb") as PackedScene).instantiate()
	add_child(model)
	model.scale = Vector3.ONE * SCALE
	model.rotation.y = PI / 2.0      # manken +Z'ye bakar; gövde +X'e baksın
	skel = model.find_child("Skeleton3D", true, false)
	mesh = model.find_child("Mannequin_F", true, false)
	for i in skel.get_bone_count():
		_bi[skel.get_bone_name(i)] = i
	_style()
	_hair()
	_build_tree()

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
	tree.add_animation_library("", load("res://proto/mocap/anim.res"))
	model.add_child(tree)
	tree.root_node = NodePath("..")
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var bt := AnimationNodeBlendTree.new()
	var loco := AnimationNodeBlendSpace1D.new()
	loco.min_space = 0.0
	loco.max_space = 6.0
	loco.sync = true
	loco.add_blend_point(_anim("Idle_Lantern"), 0.0)
	loco.add_blend_point(_anim("Walk"), 0.9)
	loco.add_blend_point(_anim("Jog_Fwd"), 3.4)
	loco.add_blend_point(_anim("Sprint"), 5.6)
	bt.add_node("loco", loco)
	var nodes := {
		"air": _anim("Jump"), "land": _anim("Jump_Land"), "roll": _anim("Roll"), "push": _anim("Push"),
		"climb": _anim("ClimbUp_1m"), "wake": _anim("LayToIdle"), "death": _anim("Death01"), "reach": _anim("Idle_Lantern"),
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

## Her kare: durum, hız ve zaman ölçeği; sonra animasyonu ilerlet ve kodla eklemeleri uygula.
func drive(st: String, speed: float, scale: float, dt: float, xfade := 0.2) -> void:
	if st != state:
		state = st
		(tree.tree_root as AnimationNodeBlendTree).get_node("state").xfade_time = xfade
		tree.set("parameters/state/transition_request", st)
	if st == "loco":
		tree.set("parameters/loco/blend_position", speed)
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
	if absf(look_pitch) > 0.001:
		_rot_global("Head", Vector3(1, 0, 0), -look_pitch * 0.7)
		_rot_global("neck_01", Vector3(1, 0, 0), -look_pitch * 0.3)
	if hold > 0.001 and hold_target != Vector3.INF:
		_aim("upperarm_r", "lowerarm_r", hold_target, hold * 0.65)
		_aim("lowerarm_r", "hand_r", hold_target, hold * 0.8)
	# kurdeleye uzanma: sol kolu hedefe doğru çevir
	var front := reach_target != Vector3.INF and (reach_target.x - global_position.x) * signf(global_transform.basis.x.x) > 0.2
	if reach > 0.001 and front:
		_aim("upperarm_l", "lowerarm_l", reach_target, reach)
		_aim("lowerarm_l", "hand_l", reach_target, reach)

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

func bone_world(n: String, local_off := Vector3.ZERO) -> Vector3:
	var bn: String = MAP.get(n, n)
	return (skel.global_transform * skel.get_bone_global_pose(_bi[bn])) * (local_off / SCALE)

func bone_xform(n: String) -> Transform3D:
	var bn: String = MAP.get(n, n)
	return skel.global_transform * skel.get_bone_global_pose(_bi[bn])
