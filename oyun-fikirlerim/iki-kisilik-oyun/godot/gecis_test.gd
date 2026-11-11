extends SceneTree
func _init() -> void:
	_run()
func _run() -> void:
	await process_frame
	change_scene_to_file("res://proto/proto.tscn")
	await create_timer(1.0).timeout
	var lv = current_scene
	var w := 0.0
	while not lv.built and w < 60.0:
		await create_timer(0.2).timeout
		w += 0.2
	await create_timer(1.0).timeout
	# finalin bittiği an: oyuncu ekrana dokunur
	lv.cine = null
	lv.phase = "done"
	var e := InputEventScreenTouch.new()
	e.index = -5
	e.pressed = true
	e.position = Vector2(400, 300)
	root.push_input(e, true)
	await create_timer(0.1).timeout
	var e2 := InputEventScreenTouch.new()
	e2.index = -5
	e2.pressed = false
	e2.position = Vector2(400, 300)
	root.push_input(e2, true)
	for k in 3:
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("OUT") + "_%d.png" % k)
		var sc = current_scene
		print("GECIS k=%d sahne=%s oyuncu=%s kamera=%s faz=%s" % [k, sc.scene_file_path if sc != null else "yok", str(sc.player.position) if sc != null and sc.get("player") != null else "-", str(sc.cam.position) if sc != null and sc.get("cam") != null else "-", str(sc.get("phase")) if sc != null else "-"])
	quit()
