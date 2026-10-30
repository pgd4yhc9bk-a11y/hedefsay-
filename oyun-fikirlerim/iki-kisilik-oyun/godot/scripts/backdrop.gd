class_name Backdrop extends Node
## Limbo tarzı sisli orman: gökyüzü, güneş ışığı, üç katman çam, sis bantları, ışık huzmeleri, vinyet ve film greni.

class PineLayer extends Node2D:
	var trees: Array = []
	var col := Color.BLACK
	var base := 590.0
	var hscale := 1.0
	func _draw() -> void:
		for t: Dictionary in trees:
			var x: float = t["x"]
			var h: float = float(t["h"]) * hscale
			var w: float = t["w"]
			var tiers: int = t["tiers"]
			var th := h / tiers
			var pts := PackedVector2Array([Vector2(x, base - h)])
			for i in range(1, tiers + 1):
				var yy := base - h + th * i
				var ww := w * i / tiers
				pts.append(Vector2(x + ww / 2.0, yy))
				pts.append(Vector2(x + ww / 3.0, yy))
			for i in range(tiers, 0, -1):
				var yy2 := base - h + th * i
				var ww2 := w * i / tiers
				pts.append(Vector2(x - ww2 / 3.0, yy2))
				pts.append(Vector2(x - ww2 / 2.0, yy2))
			draw_colored_polygon(pts, col)
			draw_rect(Rect2(x - 4.0, base - 30.0, 8.0, 40.0), col)

var pines: Array[PineLayer] = []
var pine_par := [0.2, 0.42, 0.7]
var fogs: Array[ColorRect] = []
var fog_par := [0.1, 0.21, 0.35]
var sun: Sprite2D
var rays: Node2D
var noise_tex: NoiseTexture2D

func _ready() -> void:
	var nz := FastNoiseLite.new()
	nz.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	nz.frequency = 0.012
	nz.fractal_octaves = 3
	noise_tex = NoiseTexture2D.new()
	noise_tex.noise = nz
	noise_tex.seamless = true
	noise_tex.width = 512
	noise_tex.height = 256
	# gökyüzü
	var sky := CanvasLayer.new()
	sky.layer = -20
	add_child(sky)
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color("#74777c"), Color("#b5b7ba"), Color("#8b8d91")])
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.height = 256
	gt.width = 4
	var sk := TextureRect.new()
	sk.texture = gt
	sk.stretch_mode = TextureRect.STRETCH_SCALE
	sk.size = Vector2(1280, 720)
	sky.add_child(sk)
	var sg := GradientTexture2D.new()
	sg.fill = GradientTexture2D.FILL_RADIAL
	sg.fill_from = Vector2(0.5, 0.5)
	sg.fill_to = Vector2(1.0, 0.5)
	var g2 := Gradient.new()
	g2.colors = PackedColorArray([Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
	sg.gradient = g2
	sg.width = 512
	sg.height = 512
	sun = Sprite2D.new()
	sun.texture = sg
	sun.position = Vector2(900, 200)
	sun.scale = Vector2(2.0, 2.0)
	sky.add_child(sun)
	# çam katmanları ve sis
	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	var cols := [Color("#6d7075"), Color("#4a4c50"), Color("#2a2b2e")]
	for l in 3:
		var pl := PineLayer.new()
		pl.col = cols[l]
		pl.base = 590.0 + l * 20.0
		pl.hscale = 0.75 + l * 0.15
		var rng := RandomNumberGenerator.new()
		rng.seed = 11 + l * 7
		var x := -100.0
		while x < 4200.0:
			pl.trees.append({"x": x, "h": 220.0 + rng.randf() * 260.0 + l * 40.0, "w": 60.0 + rng.randf() * 50.0 + l * 10.0, "tiers": 4 + rng.randi() % 3})
			x += 90.0 + rng.randf() * 190.0 - l * 20.0
		back.add_child(pl)
		pines.append(pl)
		var fog := _fog_rect(Rect2(0, 320 + l * 70, 1280, 256), 0.55 - l * 0.1)
		back.add_child(fog)
		fogs.append(fog)
	rays = Node2D.new()
	back.add_child(rays)
	for i in 4:
		var pg := Polygon2D.new()
		pg.polygon = PackedVector2Array([Vector2(0, 0), Vector2(90, 0), Vector2(-140, 720), Vector2(-330, 720)])
		pg.color = Color(1, 1, 1, 0.07)
		pg.position = Vector2(300 + i * 330, 0)
		rays.add_child(pg)
	# ön katman
	var front := CanvasLayer.new()
	front.layer = 5
	add_child(front)
	var ff := _fog_rect(Rect2(0, 380, 1280, 256), 0.16)
	front.add_child(ff)
	fogs.append(ff)
	var vg := ColorRect.new()
	vg.size = Vector2(1280, 720)
	vg.material = _mat("res://shaders/vignette.gdshader")
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(vg)
	var gr := ColorRect.new()
	gr.size = Vector2(1280, 720)
	gr.material = _mat("res://shaders/grain.gdshader")
	gr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(gr)

func _mat(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	return m

func _fog_rect(r: Rect2, strength: float) -> ColorRect:
	var c := ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _mat("res://shaders/fog.gdshader")
	m.set_shader_parameter("noise_tex", noise_tex)
	m.set_shader_parameter("strength", strength)
	c.material = m
	return c

func update(cam_x: float) -> void:
	for i in 3:
		pines[i].position.x = -cam_x * pine_par[i]
	for i in fogs.size():
		var par: float = fog_par[i] if i < 3 else 0.6
		(fogs[i].material as ShaderMaterial).set_shader_parameter("scroll", cam_x * par / 1280.0)
	sun.position.x = 900.0 - cam_x * 0.03
	rays.position.x = -fmod(cam_x * 0.35, 330.0)
