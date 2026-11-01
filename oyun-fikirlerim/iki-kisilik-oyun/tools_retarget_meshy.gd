extends Node3D
## Tek seferlik araç: UAL animasyonlarını (anim.res, UE manken iskeleti) bir Meshy modelinin iskeletine aktarır.
## Yöntem: her karede kaynak kemiğin dünya dönüşü, dinlenme pozuna göre fark olarak hedef kemiğe uygulanır
## (G_hedef = (G_kaynak * G_kaynak_dinlenme⁻¹) * G_hedef_dinlenme). Kalça konumu boy oranıyla ölçeklenir.
## Modelin ve ek dosyaların kendi animasyonları "M_" önekiyle eklenir.
## Çalıştırma: godot --headless --path godot res://proto/retarget.tscn -- --hedef=nehir|cinar
const SRC := "res://proto/mocap/manken_kiz.glb"
const FPS := 30.0
const JOBS := {
	"nehir": {"model": "res://proto/mocap/nehir_meshy.glb", "ek": ["res://proto/mocap/ek/nehir_animlar1.glb", "res://proto/mocap/ek/nehir_animlar2.glb"], "out": "res://proto/mocap/anim_nehir.res"},
	"cinar": {"model": "res://proto/mocap/cinar_meshy.glb", "ek": [], "out": "res://proto/mocap/anim_cinar.res"},
}
# UAL (UE) kemik adı -> hedef kemik adı (Mixamo); listede olmayanlar aynı ad
const MIXAMO := {"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2", "neck_01": "Neck", "Head": "Head",
	"clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm", "hand_l": "LeftHand",
	"clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm", "hand_r": "RightHand",
	"thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
	"thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase",
	"thumb_01_l": "LeftHandThumb1", "thumb_02_l": "LeftHandThumb2", "thumb_03_l": "LeftHandThumb3",
	"index_01_l": "LeftHandIndex1", "index_02_l": "LeftHandIndex2", "index_03_l": "LeftHandIndex3",
	"middle_01_l": "LeftHandMiddle1", "middle_02_l": "LeftHandMiddle2", "middle_03_l": "LeftHandMiddle3",
	"ring_01_l": "LeftHandRing1", "ring_02_l": "LeftHandRing2", "ring_03_l": "LeftHandRing3",
	"pinky_01_l": "LeftHandPinky1", "pinky_02_l": "LeftHandPinky2", "pinky_03_l": "LeftHandPinky3",
	"thumb_01_r": "RightHandThumb1", "thumb_02_r": "RightHandThumb2", "thumb_03_r": "RightHandThumb3",
	"index_01_r": "RightHandIndex1", "index_02_r": "RightHandIndex2", "index_03_r": "RightHandIndex3",
	"middle_01_r": "RightHandMiddle1", "middle_02_r": "RightHandMiddle2", "middle_03_r": "RightHandMiddle3",
	"ring_01_r": "RightHandRing1", "ring_02_r": "RightHandRing2", "ring_03_r": "RightHandRing3",
	"pinky_01_r": "RightHandPinky1", "pinky_02_r": "RightHandPinky2", "pinky_03_r": "RightHandPinky3"}

func _ready() -> void:
	var job := "nehir"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hedef="):
			job = a.substr(8)
	var J: Dictionary = JOBS[job]
	var src: Node3D = (load(SRC) as PackedScene).instantiate()
	add_child(src)
	var ss: Skeleton3D = src.find_child("Skeleton3D", true, false)
	var dst: Node3D = (load(J["model"]) as PackedScene).instantiate()
	add_child(dst)
	var ds: Skeleton3D = dst.find_child("Skeleton3D", true, false)
	var dpath := str(dst.get_path_to(ds))
	var ap := AnimationPlayer.new()
	src.add_child(ap)
	ap.root_node = NodePath("..")
	var lib_in: AnimationLibrary = load("res://proto/mocap/anim.res")
	ap.add_animation_library("", lib_in)
	await get_tree().process_frame
	# eşleme: hedef kemik -> kaynak kemik (Mixamo ön eki "mixamorig:" ve benzerleri temizlenir)
	var pairs := {}
	for si in ss.get_bone_count():
		var sn := ss.get_bone_name(si)
		var want: String = MIXAMO.get(sn, sn) if job == "cinar" else ("head" if sn == "Head" else sn)
		for di in ds.get_bone_count():
			var dn := ds.get_bone_name(di)
			var bare := dn.trim_prefix("mixamorig:").trim_prefix("mixamorig_")
			if bare == want:
				pairs[di] = si
	print("hedef=", job, " yol=", dpath, " eslesen kemik: ", pairs.size(), "/", ds.get_bone_count())
	var hips_d := -1
	for di in ds.get_bone_count():
		if pairs.has(di) and ss.get_bone_name(pairs[di]) == "pelvis":
			hips_d = di
	var hip_ratio := ds.get_bone_global_rest(hips_d).origin.y / ss.get_bone_global_rest(ss.find_bone("pelvis")).origin.y
	var out := AnimationLibrary.new()
	for an in lib_in.get_animation_list():
		var a: Animation = lib_in.get_animation(an)
		var na := Animation.new()
		na.length = a.length
		na.loop_mode = a.loop_mode
		var rot_tr := {}
		for di: int in pairs:
			var t := na.add_track(Animation.TYPE_ROTATION_3D)
			na.track_set_path(t, NodePath("%s:%s" % [dpath, ds.get_bone_name(di)]))
			rot_tr[di] = t
		var ptr := na.add_track(Animation.TYPE_POSITION_3D)
		na.track_set_path(ptr, NodePath("%s:%s" % [dpath, ds.get_bone_name(hips_d)]))
		ap.play(an)
		var n := int(ceil(a.length * FPS))
		for f in n + 1:
			var tt := minf(a.length, f / FPS)
			ap.seek(tt, true)
			ss.force_update_all_bone_transforms()
			var gt := {}
			for i in ds.get_bone_count():
				var par := ds.get_bone_parent(i)
				var pb: Basis = gt[par] if par >= 0 else Basis()
				var g: Basis
				if pairs.has(i):
					var si: int = pairs[i]
					var gs := ss.get_bone_global_pose(si).basis.orthonormalized()
					var gsr := ss.get_bone_global_rest(si).basis.orthonormalized()
					var gdr := ds.get_bone_global_rest(i).basis.orthonormalized()
					g = (gs * gsr.inverse()) * gdr
					na.rotation_track_insert_key(rot_tr[i], tt, (pb.inverse() * g).orthonormalized().get_rotation_quaternion())
				else:
					g = pb * ds.get_bone_rest(i).basis.orthonormalized()
				gt[i] = g
			var sp := ss.get_bone_global_pose(ss.find_bone("pelvis")).origin
			var spr := ss.get_bone_global_rest(ss.find_bone("pelvis")).origin
			var dpr := ds.get_bone_global_rest(hips_d).origin
			var gpos := dpr + (sp - spr) * hip_ratio
			var pp := ds.get_bone_parent(hips_d)
			var lpos := gpos if pp < 0 else (ds.get_bone_global_rest(pp).affine_inverse() * gpos)
			na.position_track_insert_key(ptr, tt, lpos)
		out.add_animation(an, na)
	# modelin ve ek dosyaların kendi animasyonları
	var files: Array = [J["model"]] + J["ek"]
	for fpath: String in files:
		var sc: Node3D = (load(fpath) as PackedScene).instantiate()
		var map: AnimationPlayer = sc.find_child("AnimationPlayer", true, false)
		if map != null:
			var esk := sc.find_child("Skeleton3D", true, false)
			var epath := str(sc.get_path_to(esk))
			for mn in map.get_animation_list():
				var ma: Animation = map.get_animation(mn).duplicate(true)
				if epath != dpath:   # iz yollarını modelin iskelet yoluna çevir
					for t in ma.get_track_count():
						var tp := str(ma.track_get_path(t))
						ma.track_set_path(t, NodePath(tp.replace(epath + ":", dpath + ":")))
				var nm := "M_" + mn
				if mn.length() > 30 and mn.begins_with("_"):   # Meshy "metinden harekete" animasyonları kod adıyla gelir: sarılma
					nm = "M_Hug"
				if mn == "Female_Bend_Over_Pick_Up_Inspect":   # yerden fener alma
					nm = "M_Pick_Up"
				if not out.has_animation(nm):
					out.add_animation(nm, ma)
		sc.free()
	print("kaydet: ", ResourceSaver.save(out, J["out"], ResourceSaver.FLAG_COMPRESS), " toplam=", out.get_animation_list().size())
	print("animasyonlar: ", ", ".join(out.get_animation_list()))
	get_tree().quit()
