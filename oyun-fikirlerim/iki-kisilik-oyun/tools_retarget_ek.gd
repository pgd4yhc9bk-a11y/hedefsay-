extends Node3D
## Meshy'den farklı (Mixamo adlı) iskeletle gelen ek animasyonları Nehir'in modeline aktarır ve anim_nehir.res'e ekler.
## Yöntem: kare kare dünya dönüşü farkı (G_hedef = G_kaynak * G_kaynak_dinlenme⁻¹ * G_hedef_dinlenme), kalça yüksekliği oranlı.
## Kök kayması çıkarılır ve döngü yapılır (yerinde oynasın).
## Çalıştırma: proto/ klasörüne retarget_ek.gd olarak kopyala + tscn; godot --headless --path godot res://proto/retarget_ek.tscn

const SRC := "res://proto/mocap/ek/nehir_animlar3.glb"
const DST := "res://proto/mocap/nehir_meshy.glb"
const LIB := "res://proto/mocap/anim_nehir.res"
const PICK := {"_01a19aaf_8c20_73a9_a96e_4316fb0a3a47": "M_TurnWheel", "_01a19ab0_b4e4_760b_b2c2_d80d2ffbb596": "M_PullRope"}
# yeni Meshy animasyonu gelince buraya kod adı -> "M_PullChain" (asansör zinciri) eklenir
const FPS := 30.0
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
	var src: Node3D = (load(SRC) as PackedScene).instantiate()
	add_child(src)
	var ss: Skeleton3D = src.find_child("Skeleton3D", true, false)
	var ap: AnimationPlayer = src.find_child("AnimationPlayer", true, false)
	var dst: Node3D = (load(DST) as PackedScene).instantiate()
	add_child(dst)
	var ds: Skeleton3D = dst.find_child("Skeleton3D", true, false)
	var dpath := str(dst.get_path_to(ds))
	await get_tree().process_frame
	var pairs := {}
	for di in ds.get_bone_count():
		var dn := ds.get_bone_name(di)
		var key := "Head" if dn == "head" else dn
		if not MIXAMO.has(key):
			continue
		var si := ss.find_bone("mixamorig_" + MIXAMO[key])
		if si >= 0:
			pairs[di] = si
	var hips_d := ds.find_bone("pelvis")
	var hips_s := ss.find_bone("mixamorig_Hips")
	print("eslesen kemik: ", pairs.size(), "/", ds.get_bone_count())
	var ratio := ds.get_bone_global_rest(hips_d).origin.y / ss.get_bone_global_rest(hips_s).origin.y
	var lib: AnimationLibrary = load(LIB)
	for an: String in PICK:
		var a: Animation = ap.get_animation(an)
		var na := Animation.new()
		na.length = a.length
		na.loop_mode = Animation.LOOP_LINEAR
		var rot_tr := {}
		for di: int in pairs:
			var t := na.add_track(Animation.TYPE_ROTATION_3D)
			na.track_set_path(t, NodePath("%s:%s" % [dpath, ds.get_bone_name(di)]))
			rot_tr[di] = t
		var ptr := na.add_track(Animation.TYPE_POSITION_3D)
		na.track_set_path(ptr, NodePath("%s:%s" % [dpath, ds.get_bone_name(hips_d)]))
		ap.play(an)
		ap.seek(0.0, true)
		ss.force_update_all_bone_transforms()
		var h0 := ss.get_bone_global_pose(hips_s).origin
		ap.seek(a.length, true)
		ss.force_update_all_bone_transforms()
		var drift := ss.get_bone_global_pose(hips_s).origin - h0
		drift.y = 0.0
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
			var sp := ss.get_bone_global_pose(hips_s).origin - drift * (tt / a.length)   # yerinde: kök kayması çıkarılır
			var spr := ss.get_bone_global_rest(hips_s).origin
			var gpos := ds.get_bone_global_rest(hips_d).origin + (sp - spr) * ratio
			var pp := ds.get_bone_parent(hips_d)
			var lpos := gpos if pp < 0 else (ds.get_bone_global_rest(pp).affine_inverse() * gpos)
			na.position_track_insert_key(ptr, tt, lpos)
		na = _loop_cut(na)
		if lib.has_animation(PICK[an]):
			lib.remove_animation(PICK[an])
		lib.add_animation(PICK[an], na)
		print("aktarildi ", an, " -> ", PICK[an], " ", a.length, " s, kok kaymasi ", drift)
	print("kaydet: ", ResourceSaver.save(lib, LIB, ResourceSaver.FLAG_COMPRESS))
	get_tree().quit()

## Döngü dikişi: pozun en çok benzediği iki an arasını keser (en az 1.6 s), kalçanın yatay farkını dağıtır.
func _loop_cut(a: Animation) -> Animation:
	var rot := []
	var pos := -1
	for t in a.get_track_count():
		if a.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			rot.append(t)
		else:
			pos = t
	var best := [0.0, a.length, INF]
	var t0 := 0.0
	while t0 < a.length - 1.6:
		var t1 := t0 + 1.6
		while t1 <= a.length:
			var e := 0.0
			for t: int in rot:
				e += a.rotation_track_interpolate(t, t0).angle_to(a.rotation_track_interpolate(t, t1))
			if e < best[2]:
				best = [t0, t1, e]
			t1 += 1.0 / 30.0
		t0 += 1.0 / 30.0
	var b0: float = best[0]
	var b1: float = best[1]
	var L := b1 - b0
	var na := Animation.new()
	na.length = L
	na.loop_mode = Animation.LOOP_LINEAR
	var dp := Vector3.ZERO
	if pos >= 0:
		dp = a.position_track_interpolate(pos, b1) - a.position_track_interpolate(pos, b0)
	for t in a.get_track_count():
		var nt := na.add_track(a.track_get_type(t))
		na.track_set_path(nt, a.track_get_path(t))
		var n := int(round(L * 30.0))
		for k in n + 1:
			var tt := minf(k / 30.0, L)
			if a.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				na.rotation_track_insert_key(nt, tt, a.rotation_track_interpolate(t, b0 + tt))
			else:
				na.position_track_insert_key(nt, tt, a.position_track_interpolate(t, b0 + tt) - dp * (tt / L))
	print("  dongu %.2f-%.2f s, dikis hatasi %.3f (ilk-son %.3f)" % [b0, b1, best[2], 0.0])
	return na
