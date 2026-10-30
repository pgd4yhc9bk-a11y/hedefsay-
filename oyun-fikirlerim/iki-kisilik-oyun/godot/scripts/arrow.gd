class_name Arrow extends Area2D
## Ok atıcıdan çıkan ok: kalkan, siper (kasa/maske/duvar) veya oyuncu tarafından durdurulur.

var vx := 0.0
var limit_w := 3000.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 | 4
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(26, 6)
	cs.shape = rs
	add_child(cs)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-13, -3), Vector2(13, -3), Vector2(13, 3), Vector2(-13, 3)])
	body.color = Color("#0b0b0c")
	add_child(body)
	var tip := Polygon2D.new()
	var tx := -13.0 if vx < 0.0 else 9.0
	tip.polygon = PackedVector2Array([Vector2(tx, -3), Vector2(tx + 4, -3), Vector2(tx + 4, 3), Vector2(tx, 3)])
	tip.color = Color("#e9e6dc")
	add_child(tip)
	body_entered.connect(_hit)

func _physics_process(delta: float) -> void:
	position.x += vx * delta
	if position.x < -60.0 or position.x > limit_w + 60.0:
		queue_free()

func _hit(b: Node) -> void:
	if b is Player:
		var p := b as Player
		if p.dead:
			return
		if p.worn and signf(vx) == -float(p.face):
			Sfx.play("block")
			queue_free()
		else:
			p.die()
	else:
		Sfx.play("block", -6.0)
		queue_free()
