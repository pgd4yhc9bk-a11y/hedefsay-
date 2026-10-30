class_name PoseRig extends Node2D
## Kare kare poz animasyonu: ChatGPT'nin çizdiği gerçekçi pozlar, durum makinesiyle seçilir; ezilme, sallanma ve eğilmeyle yumuşatılır.
## Karakter: "nehir" | "cinar". Pozlar assets/<karakter>/poz/ içinde, çapa (ayak noktası) poses.json'da.

var who := "nehir"
var meta := {}
var tex := {}
var spr: Sprite2D
var cur := ""
var _cur_t := 0.0
var _blend := 1.0
var _last_pose := ""

func _ready() -> void:
	var f := FileAccess.open("res://assets/poses.json", FileAccess.READ)
	var all: Dictionary = JSON.parse_string(f.get_as_text())
	meta = all[who]
	for n: String in meta:
		tex[n] = load("res://assets/%s/poz/%s.png" % [who, n])
	spr = Sprite2D.new()
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(spr)

func _pick(p: Player, t: float) -> String:
	var spd := absf(p.velocity.x)
	var grounded := p.is_on_floor()
	var n := "nehir" == who
	if not grounded:
		if p.velocity.y < 0.0:
			return "01_ziplama_yukselis" if n else "05_ziplama_yukselis"
		if p.fall_t > 0.12 and p.velocity.y > 260.0:
			return "06_dusme" if n else "07_dusme"
		return "05_ziplama_tepe" if n else "06_ziplama_tepe"
	if p.recover > 0.5:
		return "08_yuvarlanma" if n else "09_yuvarlanma"
	if p.recover > 0.0 or p.squash > 0.0:
		return "07_inis_comelme" if n else "08_inis_comelme"
	if p.on_ice and spd > 25.0:
		return "09_kayma_sendeleme" if n else "10_buzda_kayma_neseli"
	if p.mud > 0 and spd > 20.0:
		return "10_camurda_yuruyus" if n else "11_camurda_yuruyus"
	if p.grab and n:
		return "12_kutu_itme" if (p.velocity.x * p.face > 0.0 or spd < 5.0) else "11_kutu_cekme"
	if spd > 20.0:
		if spd > 120.0:
			return "04_kosma"
		var step := int(floor(p.anim)) % 2 == 0
		if n:
			return "02_yuruyus_a" if step else "03_yuruyus_b"
		return "01_yuruyus_a" if step else "03_yuruyus_b"
	return "03_yuruyus_b" if n else "13_bekleme_yukari_bakis"

func update_pose(p: Player, t: float) -> void:
	var name := _pick(p, t)
	if not meta.has(name):
		name = meta.keys()[0]
	var m: Dictionary = meta[name]
	spr.texture = tex[name]
	var k := 1.0 / float(m["res"])          # çıkış pikseli -> oyun pikseli
	spr.scale = Vector2(k, k)
	spr.offset = Vector2(-float(m["ax"]), -float(m["ay"]))
	# yumuşatma: yürürken sekme, bekleyişte nefes, inişte ezilme
	var bob := 0.0
	var spd := absf(p.velocity.x)
	if p.is_on_floor():
		if spd > 20.0:
			bob = -absf(sin(p.anim * PI)) * 2.0
		else:
			bob = sin(t * 1.8) * 0.5
	position.y = bob
	var sqk := 1.0 - p.squash * 0.9 if p.squash > 0.0 else 1.0
	scale = Vector2(p.face * (2.0 - sqk), sqk)
	rotation = 0.0
	if p.is_on_floor() and spd > 120.0:
		rotation = p.face * 0.03 * sin(p.anim * PI * 2.0)

func ember_world(p: Player) -> Vector2:
	return p.global_position + Vector2(0, -30)

func hand_world(p: Player) -> Vector2:
	return p.global_position + Vector2(p.face * 14.0, -26.0)
