extends SceneTree
## Tek seferlik: UAL glb dosyalarından gereken animasyonları ayıkla -> res://proto/mocap/anim.res
const KEEP := ["Idle", "Idle_Torch", "Walk", "Jog_Fwd", "Sprint", "Jump_Start", "Jump", "Jump_Land",
	"Push", "Roll", "Death01", "Interact", "Crouch_Idle", "Crouch_Fwd", "Hit_Chest",
	"ClimbUp_1m", "Idle_Lantern", "LayToIdle", "Idle_Rail", "Hit_Knockback", "NinjaJump_Land", "Idle_No", "Walk_Carry"]
func _init() -> void:
	var lib := AnimationLibrary.new()
	for f in ["res://proto/ual_src/ual1.glb", "res://proto/ual_src/ual2.glb"]:
		var sc: Node = (load(f) as PackedScene).instantiate()
		var ap: AnimationPlayer = sc.find_child("AnimationPlayer", true, false)
		print(f, " yol: ", sc.get_path_to(ap), " kök: ", ap.root_node)
		for n in ap.get_animation_list():
			if n in KEEP:
				var a: Animation = ap.get_animation(n).duplicate(true)
				lib.add_animation(n, a)
				print("  ", n, " ", snappedf(a.length, 0.01), "s dongu=", a.loop_mode, " izler=", a.get_track_count())
		sc.free()
	print("kaydet: ", ResourceSaver.save(lib, "res://proto/mocap/anim.res", ResourceSaver.FLAG_COMPRESS))
	var m: Node = (load("res://proto/mocap/manken_kiz.glb") as PackedScene).instantiate()
	_dump(m, "")
	m.free()
	quit()
func _dump(n: Node, ind: String) -> void:
	print(ind, n.name, " (", n.get_class(), ")")
	for c in n.get_children():
		_dump(c, ind + "  ")
