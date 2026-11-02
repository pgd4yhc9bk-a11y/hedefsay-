extends CharacterBody3D
## Çınar: bekle, hedefe git, Nehir'i takip et. Komutlar bölüm tarafından doğrulanır.
var level: Node3D
var mode := "follow"
var target_x := 0.0
var model: NehirMocap
var turn: Node3D
var lever_stage := ""
var clip_left := 0.0
var nod_left := 0.0
var hopping := false

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
	model.tree.add_animation_library("cooperate", preload("res://proto/mocap/birlikte_cinar.res"))

func command(kind: String, x := 0.0, acknowledge := true) -> void:
	if kind != "stay" and lever_stage in ["pull", "hold"]:
		lever_stage = "release"
		clip_left = model.tree.get_animation("cooperate/LeverRelease").length
	elif kind == "stay" and acknowledge and lever_stage == "":
		nod_left = model.tree.get_animation("cooperate/Nod").length
		model.any_name = ""
	if kind != "stay": nod_left = 0
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
	var tunnel := position.x > 150.5 and position.x < 155.5
	var speed := 3.6 if mode == "follow" and absf(dx) > 3.0 else 2.8
	if tunnel: speed = 0.9
	velocity.x = move_toward(velocity.x, clampf(dx * 2.0, -speed, speed) if mode != "stay" else 0.0, dt * 9.0)
	if lever_stage == "release": velocity.x = 0
	velocity.y = -0.5 if is_on_floor() else velocity.y - 21.0 * dt
	# Alçak kütük ve kasa aşılır; yüksek kapılara atlanmaz.
	var obstacles: Array = level.route_obstacles.duplicate()
	if level.crate != null: obstacles.append(level.crate)
	if is_on_floor() and mode != "stay":
		for obstacle: Node3D in obstacles:
			if absf(obstacle.position.x - position.x) < 1.2 and position.y < obstacle.position.y + 0.8 and signf(dx) == signf(obstacle.position.x - position.x):
				velocity.y = 7.8
				hopping = true
				model.any_name = ""
				break
	move_and_slide()
	position.z = 0.0
	if mode == "go" and absf(position.x - target_x) < 0.12:
		command("stay", 0, false)
	if absf(velocity.x) > 0.05:
		turn.rotation.y = move_toward(turn.rotation.y, 0.0 if velocity.x > 0 else -PI, dt * 7.0)
	animate_companion(dt, tunnel)
	if position.y < level.ground_y(position.x) - 4.0:
		level.restore_checkpoint()

func reset_interaction() -> void:
	lever_stage = ""
	clip_left = 0
	nod_left = 0
	hopping = false

func animate_companion(dt: float, tunnel: bool) -> void:
	var holding: bool = mode == "stay" and is_on_floor() and level.companion_lever()
	if holding and lever_stage == "":
		lever_stage = "pull"
		clip_left = model.tree.get_animation("cooperate/LeverPull").length
		nod_left = 0
	elif not holding and lever_stage in ["pull", "hold"]:
		lever_stage = "release"
		clip_left = model.tree.get_animation("cooperate/LeverRelease").length
	var clip := ""
	var rate := 1.0
	if lever_stage != "":
		clip = {"pull":"LeverPull", "hold":"LeverHold", "release":"LeverRelease"}[lever_stage]
		turn.rotation.y = move_toward(turn.rotation.y, 0, dt * 7)
		if lever_stage != "hold":
			clip_left -= dt
			if clip_left <= 0:
				lever_stage = "hold" if lever_stage == "pull" else ""
	elif not is_on_floor() and hopping:
		clip = "Hop"
		rate = 2.4   # Fizik sıçramasına uysun; kaynakta ayrıca yukarı kök kayması yok.
	elif tunnel and absf(velocity.x) > 0.05:
		clip = "CrouchWalk"
		rate = maxf(0.1, absf(velocity.x) / 0.45)
	elif nod_left > 0 and mode == "stay":
		clip = "Nod"
		nod_left = maxf(0, nod_left - dt)
	if is_on_floor(): hopping = false
	if clip != "":
		model.set_any("cooperate/" + clip)
		model.drive("any", absf(velocity.x), rate, dt)
	else:
		model.drive("loco" if is_on_floor() else "air", absf(velocity.x), 1.0, dt)
