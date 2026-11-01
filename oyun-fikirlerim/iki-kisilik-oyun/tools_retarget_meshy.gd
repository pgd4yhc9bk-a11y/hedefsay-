extends Node3D
## Tek seferlik araç: UAL animasyonlarını (anim.res, UE manken iskeleti) Meshy modelinin iskeletine aktarır.
## Yöntem: her karede kaynak kemiğin dünya dönüşü, dinlenme pozuna göre fark olarak hedef kemiğe uygulanır
## (G_hedef = (G_kaynak * G_kaynak_dinlenme⁻¹) * G_hedef_dinlenme). Kalça konumu boy oranıyla ölçeklenir.
## Meshy'nin kendi animasyonları "M_" önekiyle eklenir. Çıktı: res://proto/mocap/anim_nehir.res
const SRC := "res://proto/mocap/manken_kiz.glb"
const DST := "res://proto/mocap/nehir_meshy.glb"
const FPS := 30.0
const NAME := {"Head": "head"}

func _ready() -> void:
	var src: Node3D = (load(SRC) as PackedScene).instantiate()
	add_child(src)
	var ss: Skeleton3D = src.find_child("Skeleton3D", true, false)
	var dst: Node3D = (load(DST) as PackedScene).instantiate()
	add_child(dst)
	var ds: Skeleton3D = dst.find_child("Skeleton3D", true, false)
	var dpath := str(dst.get_path_to(ds))
	var ap := AnimationPlayer.new()
	src.add_child(ap)
	ap.root_node = NodePath("..")
	var lib_in: AnimationLibrary = load("res://proto/mocap/anim.res")
	ap.add_animation_library("", lib_in)
	await get_tree().process_frame
	# eşleme: hedef kemik -> kaynak kemik
	var pairs := []
	for i in ds.get_bone_count():
		var dn := ds.get_bone_name(i)
		var sn := dn
		for k: String in NAME:
			if NAME[k] == dn:
				sn = k
		var si := ss.find_bone(sn)
		if si >= 0:
			pairs.append([i, si])
	print("eslesen kemik: ", pairs.size(), "/", ds.get_bone_count())
	var hip_ratio := ds.get_bone_global_rest(ds.find_bone("pelvis")).origin.y / ss.get_bone_global_rest(ss.find_bone("pelvis")).origin.y
	var out := AnimationLibrary.new()
	for an in lib_in.get_animation_list():
		var a: Animation = lib_in.get_animation(an)
		var na := Animation.new()
		na.length = a.length
		na.loop_mode = a.loop_mode
		var rot_tr := {}
		for p: Array in pairs:
			var t := na.add_track(Animation.TYPE_ROTATION_3D)
			na.track_set_path(t, NodePath("%s:%s" % [dpath, ds.get_bone_name(p[0])]))
			rot_tr[p[0]] = t
		var ptr := na.add_track(Animation.TYPE_POSITION_3D)
		na.track_set_path(ptr, NodePath("%s:pelvis" % dpath))
		ap.play(an)
		var n := int(ceil(a.length * FPS))
		for f in n + 1:
			var tt := minf(a.length, f / FPS)
			ap.seek(tt, true)
			ss.force_update_all_bone_transforms()
			var gt := {}   # hedef kemiklerin bu karedeki dünya (iskelet uzayı) dönüşleri
			for i in ds.get_bone_count():
				var src_i := -1
				for p: Array in pairs:
					if p[0] == i:
						src_i = p[1]
						break
				var par := ds.get_bone_parent(i)
				var pb: Basis = gt[par] if par >= 0 else Basis()
				var g: Basis
				if src_i >= 0:
					var gs := ss.get_bone_global_pose(src_i).basis.orthonormalized()
					var gsr := ss.get_bone_global_rest(src_i).basis.orthonormalized()
					var gdr := ds.get_bone_global_rest(i).basis.orthonormalized()
					g = (gs * gsr.inverse()) * gdr
					na.rotation_track_insert_key(rot_tr[i], tt, (pb.inverse() * g).orthonormalized().get_rotation_quaternion())
				else:
					g = pb * ds.get_bone_rest(i).basis.orthonormalized()
				gt[i] = g
			var sp := ss.get_bone_global_pose(ss.find_bone("pelvis")).origin
			var spr := ss.get_bone_global_rest(ss.find_bone("pelvis")).origin
			var dpr := ds.get_bone_global_rest(ds.find_bone("pelvis")).origin
			var gpos := dpr + (sp - spr) * hip_ratio
			var pp := ds.get_bone_parent(ds.find_bone("pelvis"))
			var lpos := gpos if pp < 0 else (ds.get_bone_global_rest(pp).affine_inverse() * gpos)
			na.position_track_insert_key(ptr, tt, lpos)
		out.add_animation(an, na)
		print("  ", an, " kare=", n + 1)
	# Meshy'nin kendi animasyonları
	var map: AnimationPlayer = dst.find_child("AnimationPlayer", true, false)
	for mn in map.get_animation_list():
		var ma: Animation = map.get_animation(mn).duplicate(true)
		out.add_animation("M_" + mn, ma)
	print("kaydet: ", ResourceSaver.save(out, "res://proto/mocap/anim_nehir.res", ResourceSaver.FLAG_COMPRESS), " toplam=", out.get_animation_list().size())
	get_tree().quit()
