class_name LevelRoot extends Node2D
## Bölüm verisinden sahne kurar ve mekanik mantığını (düğme, kapı, testere, ok atıcı) yürütür.

signal exit_reached
signal checkpoint_reached(idx: int, pos_x: float)

const BLACK := Color("#0b0b0c")
var data: Dictionary
var player: Player
var players: Array = []
var light_pos := Vector2(-9999, -9999)   # Kül'ün köz konumu (yoksa çok uzakta)
var ghosts: Array = []
var exit_in := {}
var crates: Array[PushBody] = []
var mask: PushBody = null
var lamp: Lamp = null
var hooks: Array = []
var plates: Array = []
var doors: Array = []
var saws: Array = []
var darts: Array = []
var water_rects: Array = []
var arrows: Node2D
var t := 0.0

func build(d: Dictionary, ps: Array) -> void:
	data = d
	players = ps
	player = ps[0] as Player
	for r: Rect2 in d["water"]:
		water_rects.append(r)
	for r: Rect2 in d["statics"]:
		_make_static(r)
	for r: Rect2 in d["water"]:
		_make_water(r)
	for r: Rect2 in d.get("ghosts", []):
		_make_ghost(r)
	for r: Rect2 in d.get("ice", []):
		_make_ice(r)
	for r: Rect2 in d.get("mud", []):
		_make_mud(r)
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
			player.worn = true
	var ld: Dictionary = d.get("lamp", {})
	if not ld.is_empty():
		lamp = Lamp.new()
		add_child(lamp)
		if ld.has("holder"):
			var hp: Player = players[ld["holder"]]
			lamp.setup(d["start"] + Vector2(13, 20))
			lamp.take(hp)
		else:
			lamp.setup(ld["pos"])
	for h: Dictionary in d.get("hooks", []):
		_make_hook(h)
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

func _make_hook(h: Dictionary) -> void:   # lamba kancası: direk + kol; ışık kapısına bağlı olabilir
	var pos: Vector2 = h["pos"]
	_poly(PackedVector2Array([Vector2(pos.x - 22, 560), Vector2(pos.x - 16, 560), Vector2(pos.x - 16, pos.y - 10), Vector2(pos.x - 22, pos.y - 10)]), BLACK)
	_poly(PackedVector2Array([Vector2(pos.x - 22, pos.y - 10), Vector2(pos.x + 2, pos.y - 10), Vector2(pos.x + 2, pos.y - 5), Vector2(pos.x - 22, pos.y - 5)]), BLACK)
	_poly(PackedVector2Array([Vector2(pos.x + 2, pos.y - 10), Vector2(pos.x + 6, pos.y - 10), Vector2(pos.x + 6, pos.y - 2), Vector2(pos.x + 2, pos.y - 2)]), BLACK)
	var eye: Polygon2D = null
	if int(h.get("door", -1)) >= 0:   # ışık gözü: lamba asılınca parlar
		var pts := PackedVector2Array()
		for i in 12:
			pts.append(Vector2(pos.x - 19 + cos(float(i) / 12.0 * TAU) * 6.0, pos.y - 24 + sin(float(i) / 12.0 * TAU) * 6.0))
		eye = _poly(pts, Color("#3a3c40"))
	hooks.append({"pos": pos, "door": int(h.get("door", -1)), "eye": eye})

func hook_near(p: Vector2, r: float) -> int:
	for i in hooks.size():
		if hook_point(i).distance_to(p) < r:
			return i
	return -1

func hook_point(i: int) -> Vector2:
	return (hooks[i]["pos"] as Vector2) + Vector2(0, 10)

func hook_active(i: int) -> bool:
	return lamp != null and lamp.state == "hung" and lamp.global_position.distance_to(hook_point(i)) < 4.0

func _make_ice(r: Rect2) -> void:   # buz: kaygan zemin (üstü parlak)
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.add_to_group("ice")
	var pm := PhysicsMaterial.new()
	pm.friction = 0.0
	sb.physics_material_override = pm
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size / 2.0
	sb.add_child(cs)
	add_child(sb)
	_poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), Color("#1d2026"))
	var sheen := Line2D.new()
	sheen.points = PackedVector2Array([r.position + Vector2(0, 1.5), Vector2(r.end.x, r.position.y + 1.5)])
	sheen.width = 3.0
	sheen.default_color = Color(0.85, 0.92, 1.0, 0.55)
	add_child(sheen)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x)
	for i in int(r.size.x / 60.0):   # buz çatlakları
		var x := r.position.x + 20.0 + i * 60.0 + rng.randf() * 20.0
		var cr := Line2D.new()
		cr.points = PackedVector2Array([Vector2(x, r.position.y + 4), Vector2(x + 8, r.position.y + 14), Vector2(x + 2, r.position.y + 24)])
		cr.width = 1.5
		cr.default_color = Color(0.8, 0.9, 1.0, 0.3)
		add_child(cr)

func _make_mud(r: Rect2) -> void:   # çamur: yavaşlatır, zor sıçratır
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(r.size.x, 14.0)
	cs.shape = rs
	cs.position = Vector2(r.position.x + r.size.x / 2.0, r.position.y - 3.0)
	a.add_child(cs)
	a.body_entered.connect(func(b: Node) -> void:
		if b is Player:
			(b as Player).mud += 1)
	a.body_exited.connect(func(b: Node) -> void:
		if b is Player:
			(b as Player).mud = maxi(0, (b as Player).mud - 1))
	add_child(a)
	var pts := PackedVector2Array([Vector2(r.position.x, r.position.y + 6.0)])
	var x := r.position.x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x) + 7
	while x < r.end.x:   # yumuşak, kabarcıklı yüzey
		pts.append(Vector2(x + 7.0, r.position.y - 3.0 - rng.randf() * 3.0))
		pts.append(Vector2(x + 14.0, r.position.y + 1.0))
		x += 14.0
	pts.append(Vector2(r.end.x, r.position.y + 6.0))
	var m := _poly(pts, Color("#1a1815"))
	m.z_index = 1

func _make_ghost(r: Rect2) -> void:   # yalnızca Kül'ün ışığı değdiğinde var olan platform
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.position + r.size / 2.0
	cs.disabled = true
	sb.add_child(cs)
	add_child(sb)
	var vis := _poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), BLACK)
	vis.modulate.a = 0.0
	ghosts.append({"rect": r, "shape": cs, "vis": vis, "lit": false})

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
			exit_in[b] = true
			if exit_in.size() >= players.size():
				exit_reached.emit())
	a.body_exited.connect(func(b: Node) -> void: exit_in.erase(b))
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
	var s := {"crates": [], "mask_active": false, "mask_pos": Vector2.ZERO, "worn": player.worn, "lamp_state": "", "lamp_pos": Vector2.ZERO, "lamp_holder": -1}
	if lamp != null:
		s["lamp_state"] = lamp.state
		s["lamp_pos"] = lamp.global_position
		s["lamp_holder"] = players.find(lamp.holder)
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
	if lamp != null:
		for pl: Player in players:
			pl.has_lamp = false
		match s["lamp_state"]:
			"held":
				lamp.take(players[s["lamp_holder"]])
			"hung":
				lamp.hang(s["lamp_pos"])
			_:
				lamp.drop(s["lamp_pos"], Vector2.ZERO)
	for a in arrows.get_children():
		a.queue_free()

func _physics_process(delta: float) -> void:
	t += delta
	# gizli platformlar: ışık değdiğinde belirir ve katı olur
	for g: Dictionary in ghosts:
		var r: Rect2 = g["rect"]
		var nearest := Vector2(clampf(light_pos.x, r.position.x, r.end.x), clampf(light_pos.y, r.position.y, r.end.y))
		var lit := nearest.distance_to(light_pos) < 215.0
		if lit != g["lit"]:
			g["lit"] = lit
			(g["shape"] as CollisionShape2D).set_deferred("disabled", not lit)
		(g["vis"] as Polygon2D).modulate.a = move_toward((g["vis"] as Polygon2D).modulate.a, 1.0 if lit else 0.0, delta * 6.0)
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
		for j in hooks.size():
			if hooks[j]["door"] == i and hook_active(j):
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
	for j in hooks.size():
		if hooks[j]["eye"] != null:
			(hooks[j]["eye"] as Polygon2D).color = Color("#ffb347") if hook_active(j) else Color("#3a3c40")
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
