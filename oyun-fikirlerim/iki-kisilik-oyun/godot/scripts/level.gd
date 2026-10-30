class_name LevelRoot extends Node2D
## Bölüm verisinden sahne kurar ve mekanik mantığını (düğme, kapı, testere, ok atıcı) yürütür.

signal exit_reached
signal checkpoint_reached(idx: int, pos_x: float)

const BLACK := Color("#0b0b0c")
var data: Dictionary
var player: Player
var crates: Array[PushBody] = []
var mask: PushBody = null
var plates: Array = []
var doors: Array = []
var saws: Array = []
var darts: Array = []
var water_rects: Array = []
var arrows: Node2D
var t := 0.0

func build(d: Dictionary, p: Player) -> void:
	data = d
	player = p
	for r: Rect2 in d["water"]:
		water_rects.append(r)
	for r: Rect2 in d["statics"]:
		_make_static(r)
	for r: Rect2 in d["water"]:
		_make_water(r)
	for pos: Vector2 in d["crates"]:
		var c := PushBody.new()
		add_child(c)
		c.setup("crate", Vector2(56, 56), pos + Vector2(28, 28), water_rects)
		crates.append(c)
	var md: Dictionary = d["mask"]
	if not md.is_empty():
		mask = PushBody.new()
		add_child(mask)
		var msz := Player.MASK_SIZE
		if md.has("pos"):
			mask.setup("mask", msz, (md["pos"] as Vector2) + msz / 2.0, water_rects)
		else:
			mask.setup("mask", msz, d["start"] + Vector2(13, 0), water_rects)
			mask.deactivate()
			p.worn = true
	for i in d["doors"].size():
		_make_door(d["doors"][i])
	for pl: Dictionary in d["plates"]:
		_make_plate(pl)
	for r: Rect2 in d["spikes"]:
		_make_spikes(r)
	for s: Dictionary in d["saws"]:
		_make_saw(s)
	arrows = Node2D.new()
	add_child(arrows)
	for dd: Dictionary in d["darts"]:
		darts.append({"d": dd, "t": float(dd["phase"])})
		var b := Polygon2D.new()
		var x: float = dd["x"]
		var y: float = dd["y"]
		var bx := x - 4.0 if int(dd["dir"]) < 0 else x - 10.0
		b.polygon = PackedVector2Array([Vector2(bx, y - 5), Vector2(bx + 14, y - 5), Vector2(bx + 14, y + 11), Vector2(bx, y + 11)])
		b.color = BLACK
		add_child(b)
	_make_exit(d["exit"])
	for i in d["checkpoints"].size():
		_make_checkpoint(i, d["checkpoints"][i])

func _poly(points: PackedVector2Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	add_child(p)
	return p

func _make_static(r: Rect2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size / 2.0
	sb.add_child(cs)
	add_child(sb)
	var pts := PackedVector2Array([r.position + Vector2(0, r.size.y), r.position])
	if r.position.y <= 560.0:   # zemin üstü pürüzlü çimen
		var rng := RandomNumberGenerator.new()
		rng.seed = int(r.position.x) + 3
		var x := r.position.x
		while x < r.end.x:
			pts.append(Vector2(minf(x + 4.0, r.end.x), r.position.y - 4.0 - rng.randf() * 10.0))
			pts.append(Vector2(minf(x + 9.0, r.end.x), r.position.y))
			x += 9.0
	pts.append(r.end)
	_poly(pts, BLACK)

func _make_water(r: Rect2) -> void:
	var p := _poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color(0.1, 0.12, 0.14, 0.93))
	p.z_index = 3
	var l := Line2D.new()
	l.points = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
	l.width = 2.0
	l.default_color = Color(1, 1, 1, 0.25)
	l.z_index = 3
	add_child(l)

func _make_door(r: Rect2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.size / 2.0
	sb.add_child(cs)
	sb.position = r.position
	add_child(sb)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)])
	vis.color = BLACK
	sb.add_child(vis)
	var hl := Polygon2D.new()
	hl.polygon = PackedVector2Array([Vector2(8, 0), Vector2(12, 0), Vector2(12, r.size.y), Vector2(8, r.size.y)])
	hl.color = Color("#2c2d30")
	vis.add_child(hl)
	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.collision_mask = 2 | 4
	var zs := CollisionShape2D.new()
	var zr := RectangleShape2D.new()
	zr.size = r.size + Vector2(8, 0)
	zs.shape = zr
	zs.position = r.position + r.size / 2.0
	zone.add_child(zs)
	add_child(zone)
	doors.append({"body": sb, "shape": cs, "vis": vis, "zone": zone, "open": 0.0, "sfx_state": false})

func _make_plate(pl: Dictionary) -> void:
	var r: Rect2 = pl["rect"]
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2 | 4
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(r.size.x, r.size.y + 6.0)
	cs.shape = rs
	cs.position = r.position + Vector2(r.size.x / 2.0, r.size.y / 2.0 - 1.0)
	a.add_child(cs)
	add_child(a)
	_poly(PackedVector2Array([Vector2(r.position.x - 8, 556), Vector2(r.end.x + 8, 556), Vector2(r.end.x + 8, 562), Vector2(r.position.x - 8, 562)]), BLACK)
	var btn := _poly(PackedVector2Array([Vector2(r.position.x, 0), Vector2(r.end.x, 0), Vector2(r.end.x, 8), Vector2(r.position.x, 8)]), Color("#55575c"))
	btn.position.y = 550.0
	plates.append({"area": a, "door": pl["door"], "heavy": pl["heavy"], "pressed": false, "was": false, "btn": btn})

func _make_spikes(r: Rect2) -> void:
	var pts := PackedVector2Array()
	var x := r.position.x
	while x < r.end.x:
		var x2 := minf(x + 12.0, r.end.x)
		pts.append(Vector2(x, r.end.y))
		pts.append(Vector2((x + x2) / 2.0, r.position.y))
		pts.append(Vector2(x2, r.end.y))
		_poly(PackedVector2Array([Vector2(x, r.end.y), Vector2((x + x2) / 2.0, r.position.y), Vector2(x2, r.end.y)]), BLACK)
		x += 12.0
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(r.size.x - 12.0, r.size.y - 4.0)
	cs.shape = rs
	cs.position = r.position + Vector2(r.size.x / 2.0, r.size.y / 2.0 + 2.0)
	a.add_child(cs)
	a.body_entered.connect(_on_hazard)
	add_child(a)

func _make_saw(s: Dictionary) -> void:
	var n := Node2D.new()
	var r: float = s["r"]
	var pts := PackedVector2Array()
	for i in 16:
		var ang := float(i) / 16.0 * TAU
		var rr := r - 8.0 if i % 2 == 1 else r + 3.0
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	var blade := Polygon2D.new()
	blade.polygon = pts
	blade.color = BLACK
	n.add_child(blade)
	var hub := Polygon2D.new()
	var hp := PackedVector2Array()
	for i in 10:
		hp.append(Vector2(cos(float(i) / 10.0 * TAU), sin(float(i) / 10.0 * TAU)) * 5.0)
	hub.polygon = hp
	hub.color = Color("#6a6c70")
	n.add_child(hub)
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = r + 6.0
	cs.shape = c
	a.add_child(cs)
	a.body_entered.connect(_on_hazard)
	n.add_child(a)
	add_child(n)
	var rail := Line2D.new()
	rail.width = 3.0
	rail.default_color = BLACK
	add_child(rail)
	saws.append({"n": n, "s": s, "blade": blade, "rail": rail})

func _make_exit(r: Rect2) -> void:
	var glow := Polygon2D.new()
	var gp := PackedVector2Array()
	for i in 24:
		gp.append(Vector2(cos(float(i) / 24.0 * TAU) * 120.0, sin(float(i) / 24.0 * TAU) * 120.0))
	glow.polygon = gp
	glow.position = r.position + Vector2(r.size.x / 2.0, 50.0)
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
	grad.gradient = g
	grad.width = 256
	grad.height = 256
	var sp := Sprite2D.new()
	sp.texture = grad
	sp.position = r.position + Vector2(r.size.x / 2.0, 50.0)
	sp.scale = Vector2(1.3, 1.3)
	add_child(sp)
	_poly(PackedVector2Array([r.position + Vector2(10, 6), r.position + Vector2(r.size.x - 10, 6), r.end - Vector2(10, 0), r.position + Vector2(10, r.size.y)]), Color("#f4f4f2"))
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size / 2.0
	a.add_child(cs)
	a.body_entered.connect(func(b: Node) -> void:
		if b is Player and not (b as Player).dead:
			exit_reached.emit())
	add_child(a)

func _make_checkpoint(i: int, x: float) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(8, 900)
	cs.shape = rs
	cs.position = Vector2(x, 360)
	a.add_child(cs)
	a.body_entered.connect(func(b: Node) -> void:
		if b is Player:
			checkpoint_reached.emit(i, x))
	add_child(a)

func _on_hazard(b: Node) -> void:
	if b is Player:
		(b as Player).die()

func snapshot() -> Dictionary:
	var s := {"crates": [], "mask_active": false, "mask_pos": Vector2.ZERO, "worn": player.worn}
	for c in crates:
		s["crates"].append(c.global_position)
	if mask != null:
		s["mask_active"] = mask.active
		s["mask_pos"] = mask.global_position
	return s

func restore(s: Dictionary) -> void:
	for i in crates.size():
		crates[i].reset_to(s["crates"][i], true)
	if mask != null:
		mask.reset_to(s["mask_pos"], s["mask_active"])
	player.worn = s["worn"]
	for a in arrows.get_children():
		a.queue_free()

func _physics_process(delta: float) -> void:
	t += delta
	# düğmeler
	for p: Dictionary in plates:
		p["was"] = p["pressed"]
		var pressed := false
		for b in (p["area"] as Area2D).get_overlapping_bodies():
			if b is PushBody and (b as PushBody).active:
				pressed = true
			elif b is Player and not p["heavy"]:
				pressed = true
		p["pressed"] = pressed
		(p["btn"] as Polygon2D).position.y = 554.0 if pressed else 550.0
		if p["was"] != pressed:
			Sfx.play("plate")
	# kapılar
	for i in doors.size():
		var dr: Dictionary = doors[i]
		var hold := false
		for p: Dictionary in plates:
			if p["door"] == i and p["pressed"]:
				hold = true
		if not hold and dr["open"] > 0.3:
			for b in (dr["zone"] as Area2D).get_overlapping_bodies():
				if b is Player or (b is PushBody and (b as PushBody).active):
					hold = true
		var o: float = dr["open"]
		if (hold and o < 0.02) or (not hold and o > 0.98):
			Sfx.play("door")
		o += ((1.0 if hold else 0.0) - o) * minf(1.0, delta * 5.0)
		if hold and o > 0.98:
			o = 1.0
		dr["open"] = o
		(dr["vis"] as Polygon2D).scale.y = 1.0 - o
		(dr["shape"] as CollisionShape2D).set_deferred("disabled", o >= 0.6)
	# testereler
	for sw: Dictionary in saws:
		var s: Dictionary = sw["s"]
		var k := (sin(t * TAU / float(s["period"])) + 1.0) / 2.0
		var pos := Vector2(lerpf(s["x1"], s["x2"], k), lerpf(s["y1"], s["y2"], k))
		(sw["n"] as Node2D).position = pos
		(sw["blade"] as Polygon2D).rotation += delta * 9.0
		if float(s["y1"]) != float(s["y2"]):
			(sw["rail"] as Line2D).points = PackedVector2Array([Vector2(pos.x, 0), pos])
	# ok atıcılar
	for dd: Dictionary in darts:
		dd["t"] += delta
		var d: Dictionary = dd["d"]
		if dd["t"] >= float(d["every"]):
			dd["t"] -= float(d["every"])
			var a := Arrow.new()
			a.vx = 420.0 * int(d["dir"])
			a.limit_w = data["w"]
			a.position = Vector2(float(d["x"]) - 13.0 if int(d["dir"]) < 0 else float(d["x"]) + 13.0, d["y"])
			arrows.add_child(a)
			if absf(float(d["x"]) - player.global_position.x) < 900.0:
				Sfx.play("fire", -10.0)
