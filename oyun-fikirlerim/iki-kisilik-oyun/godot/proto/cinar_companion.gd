extends CharacterBody3D
## Çınar: bekle, hedefe git, Nehir'i takip et. Komutlar bölüm tarafından doğrulanır.
var level: Node3D
var mode := "follow"
var target_x := 0.0
var model: NehirMocap
var turn: Node3D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 8 | 4
	floor_snap_length = 0.3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.16
	capsule.height = 1.05
	shape.shape = capsule
	shape.position.y = 0.525
	add_child(shape)
	turn = Node3D.new()
	add_child(turn)
	model = NehirMocap.new()
	model.who = "cinar"
	model.height = 1.15
	turn.add_child(model)

func command(kind: String, x := 0.0) -> void:
	mode = kind
	target_x = x if kind == "go" else position.x
	velocity.x = 0.0

func _physics_process(dt: float) -> void:
	if level.phase != "play":
		velocity = Vector3.ZERO
		return
	var wanted := target_x
	if mode == "follow":
		wanted = level.player.position.x - 1.3
	wanted = level.safe_target(position.x, wanted)
	var dx := wanted - position.x
	var speed := 3.6 if mode == "follow" and absf(dx) > 3.0 else 2.8
	velocity.x = move_toward(velocity.x, clampf(dx * 2.0, -speed, speed) if mode != "stay" else 0.0, dt * 9.0)
	velocity.y = -0.5 if is_on_floor() else velocity.y - 21.0 * dt
	# Takip sırasında kasanın arkasında kalmasın; yüksek duvarlara atlamaz.
	if is_on_floor() and mode != "stay" and level.crate != null:
		var obstacle: Node3D = level.crate
		if absf(obstacle.position.x - position.x) < 1.2 and position.y < obstacle.position.y + 0.8 and signf(dx) == signf(obstacle.position.x - position.x):
			velocity.y = 7.8
	move_and_slide()
	position.z = 0.0
	if mode == "go" and absf(position.x - target_x) < 0.12:
		command("stay")
	if absf(velocity.x) > 0.05:
		turn.rotation.y = move_toward(turn.rotation.y, 0.0 if velocity.x > 0 else -PI, dt * 7.0)
	model.drive("loco" if is_on_floor() else "air", absf(velocity.x), 1.0, dt)
	if position.y < -4.0:
		level.restore_checkpoint()
