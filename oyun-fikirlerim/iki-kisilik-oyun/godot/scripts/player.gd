class_name Player extends CharacterBody2D
## Kabuk: ağır, ivmeli hareket; kasa itme/çekme; maske tak/fırlat.

signal died

const SIZE := Vector2(26, 54)
const MASK_SIZE := Vector2(39, 67)

var face := 1
var worn := false
var grab := false
var anim := 0.0
var squash := 0.0
var recover := 0.0
var coyote := 0.0
var jump_buf := 0.0
var dead := false
var override := {}               # test için: {"left": true, ...}
var level: LevelRoot
var rig: Rig
var skin := "kabuk"        # "kabuk" | "kul"
var prefix := ""           # yerel co-op: "p1_" / "p2_"
var _last_step := 0
var _edge := {"jump": false, "mask": false}
var _gravity := 2300.0
var _drag_t := 0.0
var t := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = SIZE
	cs.shape = rs
	cs.position = Vector2(0, -SIZE.y / 2.0)
	add_child(cs)
	rig = Rig.new()
	rig.skin = skin
	add_child(rig)
	floor_snap_length = 4.0
	floor_stop_on_slope = true
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _in(n: String) -> bool:
	if override.has(n):
		return override[n]
	var a := prefix + n
	return InputMap.has_action(a) and Input.is_action_pressed(a)

func _adjacent() -> Dictionary:
	var pr := Rect2(global_position.x - SIZE.x / 2.0, global_position.y - SIZE.y, SIZE.x, SIZE.y)
	for n in get_tree().get_nodes_in_group("push"):
		var b := n as PushBody
		if b == null or not b.active:
			continue
		var r := b.rect()
		if not (pr.end.y > r.position.y + 6.0 and pr.position.y < r.end.y):
			continue
		if absf(pr.end.x - r.position.x) < 5.0:
			return {"b": b, "side": 1}
		if absf(r.end.x - pr.position.x) < 5.0:
			return {"b": b, "side": -1}
	return {}

func _physics_process(delta: float) -> void:
	if dead:
		return
	t += delta
	var grounded := is_on_floor()
	var d := int(_in("right")) - int(_in("left"))
	var adj := _adjacent()
	grab = skin == "kabuk" and _in("grab") and grounded and not adj.is_empty()
	recover = maxf(0.0, recover - delta)
	var speed := 175.0 if skin == "kul" else 165.0
	if grab:
		speed = 85.0
	elif worn:
		speed = 120.0
	if recover > 0.0:
		speed *= 0.35
	if grab:
		face = adj["side"]
	elif d != 0:
		face = d
	var accel := 260.0
	if grounded:
		accel = 900.0 if d != 0 else 1500.0
	velocity.x = move_toward(velocity.x, d * speed, accel * delta)
	# zıplama (kısa süre geç zıplama ve erken basma toleransı)
	var j := _in("jump")
	if j and not _edge["jump"]:
		jump_buf = 0.12
	_edge["jump"] = j
	var m := _in("mask")
	if m and not _edge["mask"]:
		mask_action()
	_edge["mask"] = m
	coyote = 0.08 if grounded else coyote - delta
	jump_buf -= delta
	if jump_buf > 0.0 and coyote > 0.0:
		velocity.y = -690.0 if skin == "kul" else (-560.0 if worn else -660.0)
		coyote = 0.0
		jump_buf = 0.0
		Sfx.play("jump")
	if not j and velocity.y < -200.0:
		velocity.y *= 0.55
	velocity.y = minf(950.0, velocity.y + _gravity * delta)
	var pre := velocity
	move_and_slide()
	# kasa itme / çekme
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var col := c.get_collider() as PushBody
		if col != null and absf(c.get_normal().x) > 0.7 and col.active and signf(pre.x) == -signf(c.get_normal().x) and absf(pre.x) > 1.0:
			col.push(-c.get_normal().x * minf(absf(pre.x), 100.0))
	if grab and not adj.is_empty():
		var moving_away: bool = (adj["side"] > 0 and velocity.x < -1.0) or (adj["side"] < 0 and velocity.x > 1.0)
		if moving_away:
			(adj["b"] as PushBody).push(velocity.x)
			_drag_t -= delta
			if _drag_t <= 0.0:
				_drag_t = 0.16
				Sfx.play("drag", -6.0)
	# iniş
	if is_on_floor() and not grounded and pre.y > 300.0:
		squash = minf(0.22, 0.06 + pre.y / 4500.0)
		Sfx.play("land", linear_to_db(clampf(pre.y / 900.0, 0.2, 1.0)))
		Game.shake(pre.y / 1400.0)
		if pre.y > 720.0:
			recover = 0.3
	if squash > 0.0:
		squash -= delta
	if absf(velocity.x) > 20.0 and is_on_floor():
		anim += delta * absf(velocity.x) / 50.0
		var f := int(floor(anim))
		if f != _last_step:
			_last_step = f
			Sfx.play("step", -8.0)
	if global_position.y > 900.0:
		die()

func _process(_delta: float) -> void:
	if rig != null and not dead:
		rig.update_pose(self, t)

func mask_action() -> void:
	if skin != "kabuk" or level == null or level.mask == null:
		return
	var m := level.mask
	if worn:
		var c := Vector2(global_position.x + face * (SIZE.x / 2.0 + MASK_SIZE.x / 2.0 + 2.0), global_position.y - MASK_SIZE.y / 2.0)
		if _free_at(c):
			worn = false
			add_collision_exception_with(m)   # fırlatılan maske kısa süre oyuncuyla çarpışmasın
			m.launch(c, Vector2(260.0 * face, -380.0))
			Sfx.play("whoosh")
			get_tree().create_timer(0.35).timeout.connect(func() -> void:
				if is_instance_valid(m):
					remove_collision_exception_with(m))
	elif m.active:
		var near := Rect2(global_position.x - SIZE.x / 2.0 - 30.0, global_position.y - SIZE.y - 10.0, SIZE.x + 60.0, SIZE.y + 20.0)
		if near.intersects(m.rect()):
			worn = true
			m.deactivate()
			Sfx.play("clink")

func _free_at(c: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = MASK_SIZE - Vector2(2, 2)
	q.shape = rs
	q.transform = Transform2D(0.0, c)
	q.collision_mask = 1 | 4
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()

func die() -> void:
	if dead:
		return
	dead = true
	rig.visible = false
	Sfx.play("die")
	Game.shake(0.6)
	died.emit()

func revive(pos: Vector2) -> void:
	dead = false
	global_position = pos
	velocity = Vector2.ZERO
	rig.visible = true
	squash = 0.0
	recover = 0.0
