class_name PushBody extends RigidBody2D
## İtilebilir kasa ve Kabuk'un maskesi. Maske suda yüzer, kasa batar.

var kind := "crate"          # "crate" | "mask"
var size := Vector2(56, 56)
var home := Vector2.ZERO
var active := true
var water_rects: Array = []
var _pushed := 0.0

func setup(k: String, sz: Vector2, center: Vector2, waters: Array) -> void:
	kind = k
	size = sz
	home = center
	water_rects = waters
	position = center
	collision_layer = 4
	collision_mask = 1 | 4
	lock_rotation = true
	mass = 6.0
	can_sleep = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	pm.bounce = 0.0
	physics_material_override = pm
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = sz
	cs.shape = rs
	cs.name = "Shape"
	add_child(cs)
	add_to_group("push")
	if kind == "mask":
		var sp := Sprite2D.new()
		sp.texture = load("res://assets/kabuk/mask.png")
		sp.scale = Vector2(sz.x / 595.0, sz.y / 1028.0)
		add_child(sp)
	else:
		queue_redraw()

func _draw() -> void:
	if kind != "crate":
		return
	var r := Rect2(-size / 2.0, size)
	draw_rect(r, Color("#121315"))
	draw_rect(r.grow(-4.0), Color("#3b3d41"), false, 3.0)
	draw_line(r.position + Vector2(6, 6), r.end - Vector2(6, 6), Color("#3b3d41"), 3.0)
	draw_line(Vector2(r.end.x - 6, r.position.y + 6), Vector2(r.position.x + 6, r.end.y - 6), Color("#3b3d41"), 3.0)

func push(vx: float) -> void:
	linear_velocity.x = vx
	_pushed = 0.12
	physics_material_override.friction = 0.0   # sürülürken zemin sürtünmesi hızı yemesin, oyuncuyla senkron kalsın

func launch(center: Vector2, vel: Vector2) -> void:
	active = true
	visible = true
	global_position = center
	freeze = false
	linear_velocity = vel
	$Shape.set_deferred("disabled", false)
	add_to_group("push")

func deactivate() -> void:
	active = false
	visible = false
	freeze = true
	linear_velocity = Vector2.ZERO
	$Shape.set_deferred("disabled", true)
	remove_from_group("push")

func reset_to(center: Vector2, is_active: bool) -> void:
	linear_velocity = Vector2.ZERO
	global_position = center
	if is_active:
		launch(center, Vector2.ZERO)
	else:
		deactivate()

func rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)

func _physics_process(delta: float) -> void:
	if not active:
		return
	_pushed -= delta
	if _pushed <= 0.0 and physics_material_override.friction < 1.0:
		physics_material_override.friction = 1.0
	if _pushed <= 0.0 and absf(linear_velocity.x) > 0.0 and absf(linear_velocity.y) < 25.0:   # yalnızca yerde kayarken sürtünme
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, 1400.0 * delta)
	var floating := false
	if kind == "mask":
		for w: Rect2 in water_rects:
			var cx := global_position.x
			var bottom := global_position.y + size.y / 2.0
			if cx > w.position.x and cx < w.end.x and bottom > w.position.y + 12.0 and global_position.y < w.position.y + 160.0:
				floating = true
				var target := w.position.y + 12.0 - size.y / 2.0
				gravity_scale = 0.0
				linear_velocity.y = clampf((target - global_position.y) * 12.0, -300.0, 300.0)
				linear_velocity.x *= 0.98
	if not floating:
		gravity_scale = 1.0
	if global_position.y > 900.0:
		reset_to(home, true)
