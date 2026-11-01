class_name NehirBody extends Node3D
## Nehir'in 3D gövdesi: glb modeli + prosedürel iskelet animasyonu (yürüme, koşma, zıplama, iniş, itme, tırmanma...).
## Tüm açılar yan düzlemde (model Z ekseni etrafında) radyan: + = ileri/yukarı dönüş.
## Bacak ve üst kol açıları dünya dikeyine göre, diğerleri ebeveyne göredir.

const JOINTS := ["lean", "spine", "chest", "neck", "head", "thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R",
	"upperarm.L", "upperarm.R", "forearm.L", "forearm.R", "hand.L", "hand.R", "hy", "hx"]

var skel: Skeleton3D
var bone := {}        # ad -> indeks
var axis := {}        # ad -> yerel dönme ekseni (model Z'nin kemik yerel karşılığı)
var rest_rot := {}
var hips_rest := Vector3.ZERO
var pose := {}        # son uygulanan poz
var mesh_inst: MeshInstance3D

func _ready() -> void:
	var sc: PackedScene = load("res://proto/nehir.glb")
	var m := sc.instantiate()
	add_child(m)
	skel = _find(m, "Skeleton3D") as Skeleton3D
	mesh_inst = _find(m, "MeshInstance3D") as MeshInstance3D
	for i in skel.get_bone_count():
		var n := skel.get_bone_name(i)
		bone[n] = i
		var g := skel.get_bone_global_rest(i).basis.orthonormalized()
		axis[n] = (g.inverse() * Vector3(0, 0, 1)).normalized()
		rest_rot[n] = skel.get_bone_rest(i).basis.get_rotation_quaternion()
	hips_rest = skel.get_bone_rest(bone["hips"]).origin
	for j: String in JOINTS:
		pose[j] = 0.0
	_style()

func _find(n: Node, cls: String) -> Node:
	if n.get_class() == cls:
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null

func _style() -> void:   # sade, mat kumaş; kenar ışığı (rim) siluetin sisten ayrılmasını sağlar
	var cols := {"ceket": Color(0.075, 0.08, 0.095), "pantolon": Color(0.045, 0.045, 0.05), "bot": Color(0.025, 0.022, 0.02),
		"ten": Color(0.36, 0.31, 0.28), "sac": Color(0.04, 0.03, 0.028)}
	var mesh := mesh_inst.mesh
	for s in mesh.get_surface_count():
		var old := mesh.surface_get_material(s)
		var nm := old.resource_name if old != null else ""
		var mt := StandardMaterial3D.new()
		mt.albedo_color = cols.get(nm, Color(0.1, 0.1, 0.1))
		mt.roughness = 0.95
		mt.rim_enabled = true
		mt.rim = 0.3
		mt.rim_tint = 0.4
		mesh_inst.set_surface_override_material(s, mt)

## Pozu uygula. p: JOINTS anahtarlarıyla sözlük.
func apply(p: Dictionary) -> void:
	pose = p
	var lean: float = p["lean"]
	_rot("hips", lean)
	_rot("spine", p["spine"])
	_rot("chest", p["chest"])
	_rot("neck", p["neck"])
	_rot("head", p["head"])
	for s in ["L", "R"]:
		_rot("thigh." + s, float(p["thigh." + s]) - lean)
		_rot("shin." + s, p["shin." + s])
		_rot("foot." + s, p["foot." + s])
		_rot("upperarm." + s, float(p["upperarm." + s]) - lean - float(p["spine"]) - float(p["chest"]))
		_rot("forearm." + s, p["forearm." + s])
		_rot("hand." + s, p["hand." + s])
	skel.set_bone_pose_position(bone["hips"], hips_rest + Vector3(p["hx"], p["hy"], 0.0))

func _rot(n: String, a: float) -> void:
	var i: int = bone[n]
	skel.set_bone_pose_rotation(i, (rest_rot[n] as Quaternion) * Quaternion(axis[n], a))

## Kemiğin dünya konumu (kafa, el, boyun: atkı / fener / örgü bağlantısı için)
func bone_world(n: String, local_off := Vector3.ZERO) -> Vector3:
	var t := skel.global_transform * skel.get_bone_global_pose(bone[n])
	return t * local_off

func bone_xform(n: String) -> Transform3D:
	return skel.global_transform * skel.get_bone_global_pose(bone[n])
