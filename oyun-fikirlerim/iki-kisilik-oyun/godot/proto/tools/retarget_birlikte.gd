extends SceneTree
## Yüklenen GLB'lerden yalnız Birlikte hareketlerini mevcut iskeletlere aktarır.
## Kullanım: godot --headless --path godot --script res://proto/tools/retarget_birlikte.gd -- nehir.glb cinar.glb
const PICKS := [
	{"_01a19dc2_390c_7256_a048_9746316251a3": "LeverPull", "_01a19dc5_e967_7417_a982_513d82e99313": "SymbolTouch"},
	{"_01a19db3_2aa6_7768_bb33_8b2064c0e0dc": "LeverPull", "_01a19db5_2d86_73ac_b5d5_b82dd39a1b09": "LeverHold", "_01a19db6_88e1_7486_b3be_e01d446ecd17": "LeverRelease", "_01a19dc0_e77b_7282_8362_b79d07a5eeca": "CrouchWalk", "_01a19dc4_c8d6_7701_a136_48fb5a66bde5": "Nod", "_01a19dc7_7fa5_7335_94aa_e09a3d80c766": "Hop"}
]
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

func _initialize() -> void:
	call_deferred("run")

func canonical(n: String) -> String:
	for key in MIXAMO:
		if n == "mixamorig_" + MIXAMO[key]: return key.to_lower()
	return n.to_lower()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Nehir ve Çınar GLB yolları gerekli")
		quit(1)
		return
	for i in 2:
		if not await retarget_job(args[i], "nehir" if i == 0 else "cinar", PICKS[i]):
			quit(1)
			return
	quit()

func retarget_job(path: String, who: String, pick: Dictionary) -> bool:
	var document := GLTFDocument.new()
	var data := GLTFState.new()
	if document.append_from_file(path, data) != OK: return false
	var src := document.generate_scene(data)
	root.add_child(src)
	var ss := src.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := src.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var dst := (load("res://proto/mocap/%s_meshy.glb" % who) as PackedScene).instantiate()
	root.add_child(dst)
	var ds := dst.find_child("Skeleton3D", true, false) as Skeleton3D
	await process_frame
	if ss == null or ap == null or ds == null: return false
	var source := {}
	for i in ss.get_bone_count(): source[canonical(ss.get_bone_name(i))] = i
	var pairs := {}
	for i in ds.get_bone_count():
		var key := canonical(ds.get_bone_name(i))
		if source.has(key): pairs[i] = source[key]
	var hd := -1
	for i in pairs:
		if canonical(ds.get_bone_name(i)) == "pelvis": hd = i
	if hd < 0 or pairs.size() < 20: return false
	var hs: int = pairs[hd]
	var ratio := ds.get_bone_global_rest(hd).origin.y / ss.get_bone_global_rest(hs).origin.y
	var dpath := str(dst.get_path_to(ds))
	var lib := AnimationLibrary.new()
	for code: String in pick:
		if not ap.has_animation(code):
			printerr("Eksik hareket: ", code)
			return false
		var a := ap.get_animation(code)
		# Kaynak döngülü işaretlenmiş olsa da son kareyi gerçekten örnekle.
		a.loop_mode = Animation.LOOP_NONE
		var out := Animation.new()
		out.length = a.length
		var tracks := {}
		for di in pairs:
			var t := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(t, NodePath("%s:%s" % [dpath, ds.get_bone_name(di)]))
			tracks[di] = t
		var ptr := out.add_track(Animation.TYPE_POSITION_3D)
		out.track_set_path(ptr, NodePath("%s:%s" % [dpath, ds.get_bone_name(hd)]))
		ap.play(code)
		for f in int(ceil(a.length * 30)) + 1:
			var tt := minf(f / 30.0, a.length)
			ap.seek(tt, true)
			ss.force_update_all_bone_transforms()
			var globals := {}
			for di in ds.get_bone_count():
				var par := ds.get_bone_parent(di)
				var pb: Basis = globals[par] if par >= 0 else Basis()
				var g: Basis
				if pairs.has(di):
					var si: int = pairs[di]
					g = ss.get_bone_global_pose(si).basis.orthonormalized() * ss.get_bone_global_rest(si).basis.orthonormalized().inverse() * ds.get_bone_global_rest(di).basis.orthonormalized()
					out.rotation_track_insert_key(tracks[di], tt, (pb.inverse() * g).orthonormalized().get_rotation_quaternion())
				else: g = pb * ds.get_bone_rest(di).basis.orthonormalized()
				globals[di] = g
			var offset := ss.get_bone_global_pose(hs).origin - ss.get_bone_global_rest(hs).origin
			# Konumu fizik yönetir; kalçanın eğilmesi korunur.
			offset.x = 0
			offset.z = 0
			if pick[code] == "Hop":
				var lift := INF
				for foot in ["ball_l", "ball_r"]:
					if source.has(foot):
						var si: int = source[foot]
						lift = minf(lift, ss.get_bone_global_pose(si).origin.y - ss.get_bone_global_rest(si).origin.y)
				if lift != INF: offset.y -= maxf(lift, 0)
			var gp := ds.get_bone_global_rest(hd).origin + offset * ratio
			var parent := ds.get_bone_parent(hd)
			out.position_track_insert_key(ptr, tt, ds.get_bone_global_rest(parent).affine_inverse() * gp if parent >= 0 else gp)
		if pick[code] in ["LeverHold", "CrouchWalk"]:
			out.loop_mode = Animation.LOOP_LINEAR
			# Son 0.15 saniyede ilk poza yumuşat; döngü sınırında sıçrama olmasın.
			for t in out.get_track_count():
				var first = out.track_get_key_value(t, 0)
				for k in out.track_get_key_count(t):
					var blend := clampf((out.track_get_key_time(t, k) - out.length + 0.15) / 0.15, 0, 1)
					if blend > 0:
						var v = out.track_get_key_value(t, k)
						out.track_set_key_value(t, k, v.slerp(first, blend) if v is Quaternion else v.lerp(first, blend))
				out.track_set_key_value(t, out.track_get_key_count(t) - 1, first)
		lib.add_animation(pick[code], out)
		print(who, " ", code, " -> ", pick[code], " ", out.length, " s; kemik ", pairs.size())
	var err := ResourceSaver.save(lib, "res://proto/mocap/birlikte_%s.res" % who, ResourceSaver.FLAG_COMPRESS)
	src.queue_free()
	dst.queue_free()
	await process_frame
	return err == OK
