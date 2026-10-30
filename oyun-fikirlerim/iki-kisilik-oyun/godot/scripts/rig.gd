class_name Rig extends Node2D
## Parça görsellerinden iskelet: kod her karede eklem açılarını hesaplar.
## Karakter değişirse yalnızca assets/<ad>/ klasörü ve anchors.json değişir.

const ORDER := ["uleg_b", "lleg_b", "uarm_b", "larm_b", "torso", "ember", "head", "uleg_f", "lleg_f", "uarm_f", "larm_f", "mask"]
var skin := "kabuk"
var A := {}                      # anchors.json
var spr := {}                    # düğüm adı -> Sprite2D
var K := {}                      # rol -> piksel ölçeği

func _ready() -> void:
	var f := FileAccess.open("res://assets/%s/anchors.json" % skin, FileAccess.READ)
	A = JSON.parse_string(f.get_as_text())
	for node_name: String in ORDER:
		var role := node_name.split("_")[0]
		if not A.has(role):
			continue
		var s := Sprite2D.new()
		s.texture = load("res://assets/%s/%s.png" % [skin, role])
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var a: Dictionary = A[role]
		var k: float = a["k"]
		K[role] = k
		var anchor := _anchor(role)
		s.offset = -anchor
		s.scale = Vector2(k, k)
		s.z_index = ORDER.find(node_name)
		add_child(s)
		spr[node_name] = s
	# maske yalnızca takılıyken görünür
	if spr.has("mask"):
		spr["mask"].visible = false

func _anchor(role: String) -> Vector2:
	var a: Dictionary = A[role]
	if role == "torso":
		return Vector2(a["hip"][0], a["hip"][1])
	if role == "head":
		return Vector2(a["neck"][0], a["neck"][1])
	if role == "mask" or role == "ember":
		return Vector2(a["w"] / 2.0, a["h"] / 2.0)
	return Vector2(a["top"][0], a["top"][1])

func _rest(role: String) -> float:
	var a: Dictionary = A[role]
	return atan2(float(a["bot"][0]) - float(a["top"][0]), float(a["bot"][1]) - float(a["top"][1]))

func _len(role: String, vertical: bool) -> float:
	var a: Dictionary = A[role]
	var dx := float(a["bot"][0]) - float(a["top"][0])
	var dy := float(a["bot"][1]) - float(a["top"][1])
	return (absf(dy) if vertical else sqrt(dx * dx + dy * dy)) * float(a["k"])

func _place(node_name: String, role: String, pos: Vector2, dir: float) -> void:
	var s: Sprite2D = spr[node_name]
	s.position = pos
	s.rotation = _rest(role) - dir

func update_pose(p: Player, t: float) -> void:
	var worn := p.worn
	var spd := absf(p.velocity.x)
	var grounded := p.is_on_floor()
	var run := grounded and spd > 20.0
	var ph := p.anim * PI
	var crouch := 0.0
	if p.squash > 0.0:
		crouch = minf(1.0, p.squash * 5.0)
	elif p.recover > 0.0:
		crouch = 0.6
	var U1 := _len("uleg", false)
	var U2 := _len("lleg", true)
	var A1 := _len("uarm", false)
	var torso: Dictionary = A["torso"]
	var tk: float = torso["k"]
	var TORSO := (float(torso["hip"][1]) - float(torso["shoulder"][1])) * tk
	var NECK := (float(torso["hip"][1]) - float(torso["neck"][1])) * tk
	var pushing: bool = p.grab
	var pulling: bool = p.grab and ((p.velocity.x > 0.0) != (p.face > 0)) and spd > 5.0
	var lean := 0.0
	if run:
		lean = 0.06 + minf(1.0, spd / 165.0) * 0.1
	if pushing:
		lean = -0.18 if pulling else 0.28
	if worn:
		lean = -0.08
	if crouch > 0.0:
		lean += 0.25 * crouch
	var l1: Dictionary
	var l2: Dictionary
	if not grounded:
		if p.velocity.y < 0.0:
			l1 = _leg(0.95, 1.25, U1, U2)
			l2 = _leg(-0.35, 0.6, U1, U2)
		else:
			l1 = _leg(0.55, 0.5, U1, U2)
			l2 = _leg(-0.3, 0.3, U1, U2)
	elif crouch > 0.0:
		l1 = _leg(0.8, 1.5 * crouch + 0.1, U1, U2)
		l2 = _leg(-0.2, 1.2 * crouch, U1, U2)
	elif run:
		var sw := 0.35 if (pushing or worn) else 0.62
		l1 = _leg(sin(ph) * sw, maxf(0.0, cos(ph)) * 0.95, U1, U2)
		l2 = _leg(-sin(ph) * sw, maxf(0.0, -cos(ph)) * 0.95, U1, U2)
	else:
		l1 = _leg(0.12, 0.05, U1, U2)
		l2 = _leg(-0.1, 0.05, U1, U2)
	var hip_y: float
	if grounded:
		hip_y = -maxf(l1.fy, l2.fy)
	else:
		hip_y = -(U1 + U2) * 0.95
	var bob := absf(sin(ph)) * 1.4 if run else sin(t * 1.8) * 0.5
	var hp := Vector2(0.0, hip_y - bob)
	var sh := hp + Vector2(sin(lean), -cos(lean)) * TORSO
	var a1: Dictionary
	var a2: Dictionary
	if worn:
		a1 = _arm(1.25, 0.25, sh, A1)
		a2 = _arm(1.05, 0.3, sh, A1)
	elif pushing:
		a1 = _arm(1.5, 0.05, sh, A1)
		a2 = _arm(1.35, 0.1, sh, A1)
	elif not grounded:
		if p.velocity.y < 0.0:
			a1 = _arm(2.5, 0.2, sh, A1)
			a2 = _arm(2.0, 0.3, sh, A1)
		else:
			a1 = _arm(1.9, 0.3, sh, A1)
			a2 = _arm(-1.2, 0.2, sh, A1)
	elif run:
		a1 = _arm(-sin(ph) * 0.7, 0.5 + maxf(0.0, sin(ph)) * 0.5, sh, A1)
		a2 = _arm(sin(ph) * 0.7, 0.5 + maxf(0.0, -sin(ph)) * 0.5, sh, A1)
	else:
		var br := sin(t * 1.8) * 0.04
		a1 = _arm(0.1 + br, 0.15, sh, A1)
		a2 = _arm(-0.12 - br, 0.15, sh, A1)
	# parçaları yerleştir
	_place("uleg_b", "uleg", hp, l2.a)
	_place("lleg_b", "lleg", hp + Vector2(l2.kx, l2.ky), l2.sa)
	_place("uarm_b", "uarm", sh, a2.a)
	_place("larm_b", "larm", Vector2(a2.ex, a2.ey), a2.ba)
	spr["torso"].position = hp
	spr["torso"].rotation = lean
	var neck := hp + Vector2(sin(lean), -cos(lean)) * NECK
	spr["head"].position = neck
	spr["head"].rotation = lean * 0.6 + (0.0 if grounded else p.velocity.y * 0.0002)
	_place("uleg_f", "uleg", hp, l1.a)
	_place("lleg_f", "lleg", hp + Vector2(l1.kx, l1.ky), l1.sa)
	_place("uarm_f", "uarm", sh, a1.a)
	_place("larm_f", "larm", Vector2(a1.ex, a1.ey), a1.ba)
	if spr.has("ember"):   # köz: göğüste, hafif nabız gibi parlar
		var e: Sprite2D = spr["ember"]
		e.position = hp + Vector2(sin(lean), -cos(lean)) * TORSO * 0.55 + Vector2(1.5, 0.0)
		var pulse := 1.0 + sin(t * 5.0) * 0.12
		e.scale = Vector2(pulse, pulse) * float(A["ember"]["k"])
	var m: Sprite2D = spr["mask"] if spr.has("mask") else null
	if m != null:
		m.visible = worn
	if worn and m != null:
		var mh := float(A["mask"]["h"]) * float(A["mask"]["k"])
		m.position = Vector2(15.0, -mh / 2.0 - 2.0 + sin(t * 1.8) * 0.6)
		m.scale = Vector2(0.065, 0.065)
	var sqk := 1.0 - p.squash * 0.9 if p.squash > 0.0 else 1.0
	scale = Vector2(p.face * (2.0 - sqk), sqk)

func ember_world(p: Player) -> Vector2:
	var s: Sprite2D = spr["ember"]
	return p.global_position + Vector2(s.position.x * p.face, s.position.y)

func _leg(a: float, bend: float, u1: float, u2: float) -> Dictionary:
	var kx := sin(a) * u1
	var ky := cos(a) * u1
	var sa := a - bend
	return {"a": a, "sa": sa, "kx": kx, "ky": ky, "fx": kx + sin(sa) * u2, "fy": ky + cos(sa) * u2}

func _arm(a: float, bend: float, sh: Vector2, a1: float) -> Dictionary:
	return {"a": a, "ba": a + bend, "ex": sh.x + sin(a) * a1, "ey": sh.y + cos(a) * a1}
