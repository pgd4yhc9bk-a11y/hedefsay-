extends Node3D
## Flow (video üretimi) için karakter referans görüntüleri: oyundaki Meshy modelleri, düz gri fon, yumuşak stüdyo ışığı.
## Önden, 3/4, yandan, arkadan + iki kardeş yan yana (boy oranı). Çıktı: flow/referans/*.png
## Çalıştırma: proto/ klasörüne kopyala, xvfb ile:  godot --path godot --rendering-driver opengl3 --resolution 1024x1024 res://proto/referans.tscn

const KARAKTER := {
	"nehir": {"glb": "res://proto/mocap/nehir_meshy.glb", "lib": "res://proto/mocap/anim_nehir.res", "boy": 1.45, "model_boy": 1.70, "anim": "Idle"},
	"cinar": {"glb": "res://proto/mocap/cinar_meshy.glb", "lib": "res://proto/mocap/anim_cinar.res", "boy": 1.15, "model_boy": 1.70, "anim": "Idle"},
}
var cam: Camera3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.62, 0.63)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.88)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	for spec in [[Vector3(-35, 35, 0), 1.0], [Vector3(-15, -140, 0), 0.45], [Vector3(-20, 160, 0), 0.35]]:
		var l := DirectionalLight3D.new()
		l.rotation_degrees = spec[0]
		l.light_energy = spec[1]
		add_child(l)
	cam = Camera3D.new()
	cam.fov = 28.0
	add_child(cam)
	var figs := {}
	for k: String in KARAKTER:
		figs[k] = _load(k)
	await get_tree().process_frame
	for k: String in KARAKTER:
		for o: Node3D in figs.values():
			o.visible = false
		var f: Node3D = figs[k]
		f.visible = true
		f.position = Vector3.ZERO
		var h: float = KARAKTER[k]["boy"]
		for a in [["onden", 0.0], ["uc_ceyrek", 40.0], ["yandan", 90.0], ["arkadan", 180.0]]:
			f.rotation_degrees.y = a[1]
			_frame(Vector3(0, h * 0.52, 0), h * 1.12)
			await _shot("%s_%s" % [k, a[0]])
		# yüz yakın plan
		f.rotation_degrees.y = 20.0
		_frame(Vector3(0, h * (0.85 if k == "nehir" else 0.82), 0), h * 0.4)
		await _shot("%s_yuz" % k)
	# ikisi yan yana (boy oranı), Nehir solda
	figs["nehir"].visible = true
	figs["cinar"].visible = true
	figs["nehir"].position = Vector3(-0.38, 0, 0)
	figs["cinar"].position = Vector3(0.38, 0, 0)
	figs["nehir"].rotation_degrees.y = 15.0
	figs["cinar"].rotation_degrees.y = -15.0
	_frame(Vector3(0, 0.75, 0), 1.7)
	await _shot("ikisi_yan_yana")
	# Pofuk (Çınar'ın bez tavşanı)
	for o: Node3D in figs.values():
		o.visible = false
	var pf: Node3D = (load("res://proto/mocap/pofuk.glb") as PackedScene).instantiate()
	add_child(pf)
	var ab := AABB()
	var first := true
	for mi in pf.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		ab = bb if first else ab.merge(bb)
		first = false
	pf.rotation_degrees.y = 25.0
	_frame(ab.get_center(), ab.size.y * 1.3)
	await _shot("pofuk")
	get_tree().quit()

func _load(k: String) -> Node3D:
	var d: Dictionary = KARAKTER[k]
	var root := Node3D.new()
	add_child(root)
	var m: Node3D = (load(d["glb"]) as PackedScene).instantiate()
	root.add_child(m)
	m.scale = Vector3.ONE * (float(d["boy"]) / float(d["model_boy"]))
	var old := m.find_child("AnimationPlayer", true, false)
	if old != null:
		old.queue_free()
	var ap := AnimationPlayer.new()
	m.add_child(ap)
	ap.root_node = NodePath("..")
	ap.add_animation_library("", load(d["lib"]))
	ap.play(d["anim"])
	ap.seek(0.4, true)
	ap.pause()
	for mi in m.find_children("*", "MeshInstance3D", true, false):   # oyundaki gibi mat kumaş ve ten
		var m3 := mi as MeshInstance3D
		for si in m3.mesh.get_surface_count():
			var base := m3.get_active_material(si)
			if base is StandardMaterial3D:
				var mt := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				mt.metallic = 0.0
				mt.metallic_texture = null
				mt.roughness = 0.9
				mt.roughness_texture = null
				mt.metallic_specular = 0.2
				mt.vertex_color_use_as_albedo = k == "nehir"
				m3.set_surface_override_material(si, mt)
	return root

func _frame(center: Vector3, size: float) -> void:
	var dist := (size * 0.5) / tan(deg_to_rad(cam.fov * 0.5))
	cam.position = center + Vector3(0, 0.05 * size, dist)
	cam.look_at(center, Vector3.UP)

func _shot(n: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../flow/referans/%s.png" % n)
	print("SHOT ", n)
