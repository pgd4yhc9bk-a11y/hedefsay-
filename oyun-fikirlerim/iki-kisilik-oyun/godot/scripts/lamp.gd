class_name Lamp extends RigidBody2D
## El lambası: elde taşınır, kancaya asılır, ortağa atılır. Işık kaynağı budur.

const SIZE := Vector2(14, 22)
var state := "free"             # held | free | hung
var holder: Player = null
var home := Vector2.ZERO
var _t := 0.0
var _shape: CollisionShape2D

func setup(pos: Vector2) -> void:
	position = pos
	home = pos
	collision_layer = 8
	collision_mask = 1          # yalnızca zemin ve duvarla çarpışır (oyuncuyu ve kasayı engellemez)
	lock_rotation = true
	mass = 0.4
	can_sleep = false
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	physics_material_override = pm
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = SIZE
	_shape.shape = rs
	add_child(_shape)
	add_to_group("lamp")
	z_index = 8

func light_pos() -> Vector2:
	return global_position + Vector2(0, -4)

func rect() -> Rect2:
	return Rect2(global_position - SIZE / 2.0, SIZE)

func take(by: Player) -> void:
	state = "held"
	holder = by
	by.has_lamp = true
	freeze = true
	linear_velocity = Vector2.ZERO
	_shape.set_deferred("disabled", true)

func hang(pos: Vector2) -> void:
	state = "hung"
	if holder != null:
		holder.has_lamp = false
	holder = null
	freeze = true
	global_position = pos
	_shape.set_deferred("disabled", true)

func drop(pos: Vector2, vel: Vector2) -> void:
	state = "free"
	if holder != null:
		holder.has_lamp = false
	holder = null
	global_position = pos
	freeze = false
	linear_velocity = vel
	_shape.set_deferred("disabled", false)

func _process(delta: float) -> void:
	_t += delta
	if state == "held" and holder != null and not holder.dead:
		global_position = holder.lamp_hand()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if state == "free" and global_position.y > 900.0:
		drop(home, Vector2.ZERO)

func _draw() -> void:
	var fl := 1.0 + sin(_t * 9.0) * 0.08 + sin(_t * 17.0) * 0.05
	# halka ve gövde
	draw_arc(Vector2(0, -12), 5.0, PI, TAU, 10, Color("#0b0b0c"), 1.6)
	draw_rect(Rect2(-6, -9, 12, 3), Color("#0b0b0c"))
	draw_rect(Rect2(-6, 8, 12, 3), Color("#0b0b0c"))
	draw_rect(Rect2(-5, -6, 10, 14), Color(1.0, 0.72, 0.38, 0.35))   # cam
	draw_line(Vector2(-5, -6), Vector2(-5, 8), Color("#0b0b0c"), 1.4)
	draw_line(Vector2(5, -6), Vector2(5, 8), Color("#0b0b0c"), 1.4)
	# alev
	var f := PackedVector2Array([Vector2(0, -7.0 * fl), Vector2(3.2, 0), Vector2(0, 5), Vector2(-3.2, 0)])
	draw_colored_polygon(f, Color("#ff8a1f"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(1.6, 1), Vector2(0, 3.5), Vector2(-1.6, 1)]), Color("#ffd27a"))
