class_name ProtoCrate extends CharacterBody3D
## İtilip çekilebilen ağır tahta kasa (1 m küp). Kendi yerçekimi var; yalnızca oyuncunun çağırdığı slide() ile kayar.

const SIZE := 1.0
var min_x := -INF
var max_x := INF
var home := Vector3.ZERO

func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 2)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(SIZE, SIZE, 1.1)
	cs.shape = bs
	cs.position = Vector3(0, SIZE / 2.0, 0)
	add_child(cs)
	_build_mesh()
	home = position

func _build_mesh() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.13, 0.1, 0.075)
	wood.roughness = 0.95
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.02
	fn.fractal_octaves = 3
	nt.noise = fn
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	wood.albedo_texture = nt
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(0.6, 3.0, 0.6)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.07, 0.055, 0.045)
	dark.roughness = 0.9
	var core := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.94, 0.94, 1.04)
	core.mesh = bm
	core.material_override = wood
	core.position = Vector3(0, 0.5, 0)
	add_child(core)
	# kenar kirişleri ve çapraz destek
	var e := 0.09
	var h := SIZE / 2.0
	var beams := [
		[Vector3(SIZE, e, e), Vector3(0, e / 2, 0.55 - e / 2)], [Vector3(SIZE, e, e), Vector3(0, SIZE - e / 2, 0.55 - e / 2)],
		[Vector3(SIZE, e, e), Vector3(0, e / 2, -0.55 + e / 2)], [Vector3(SIZE, e, e), Vector3(0, SIZE - e / 2, -0.55 + e / 2)],
		[Vector3(e, SIZE, e), Vector3(-h + e / 2, h, 0.55 - e / 2)], [Vector3(e, SIZE, e), Vector3(h - e / 2, h, 0.55 - e / 2)],
		[Vector3(e, SIZE, e), Vector3(-h + e / 2, h, -0.55 + e / 2)], [Vector3(e, SIZE, e), Vector3(h - e / 2, h, -0.55 + e / 2)],
		[Vector3(e, e, 1.1), Vector3(-h + e / 2, e / 2, 0)], [Vector3(e, e, 1.1), Vector3(h - e / 2, e / 2, 0)],
		[Vector3(e, e, 1.1), Vector3(-h + e / 2, SIZE - e / 2, 0)], [Vector3(e, e, 1.1), Vector3(h - e / 2, SIZE - e / 2, 0)],
	]
	for b: Array in beams:
		var mi := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = b[0]
		mi.mesh = m
		mi.position = b[1]
		mi.material_override = dark
		add_child(mi)
	var diag := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(1.25, 0.08, 0.04)
	diag.mesh = dm
	diag.material_override = dark
	diag.position = Vector3(0, h, 0.535)
	diag.rotation.z = PI / 4.0
	add_child(diag)

func _physics_process(dt: float) -> void:
	if not is_on_floor():
		velocity.y -= 21.0 * dt
	else:
		velocity.y = minf(velocity.y, 0.0)
	velocity.x = 0.0
	move_and_slide()
	position.z = 0.0

## Kasayı yatayda kaydır; gerçekte ne kadar kaydığını döndürür.
func slide(dx: float) -> float:
	if position.x + dx < min_x:
		dx = min_x - position.x
	if position.x + dx > max_x:
		dx = max_x - position.x
	if absf(dx) < 0.00001:
		return 0.0
	var x0 := position.x
	var col := move_and_collide(Vector3(dx, 0, 0))
	position.z = 0.0
	return position.x - x0 if col != null else dx

func top() -> float:
	return position.y + SIZE
