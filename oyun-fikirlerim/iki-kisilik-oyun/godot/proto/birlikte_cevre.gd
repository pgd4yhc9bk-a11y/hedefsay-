extends Node3D
## Birlikte: patika, orman katmanları ve her durağın mimarisi.
const PROFILE := [Vector2(-12, 0), Vector2(12, 0), Vector2(30, 3.2), Vector2(43, 3.2), Vector2(56, 0), Vector2(80, 0), Vector2(99, -2), Vector2(112, -2), Vector2(136, 0), Vector2(169, 0), Vector2(190, 4), Vector2(206, 4), Vector2(234, 0), Vector2(264, 0), Vector2(281, -2.2), Vector2(296, -2.2), Vector2(329, 0), Vector2(368, 0), Vector2(390, 2.8), Vector2(405, 2.8), Vector2(426, 0), Vector2(465, 0), Vector2(487, -1.8), Vector2(505, -1.8), Vector2(540, 0), Vector2(593, 0), Vector2(615, 3), Vector2(638, 3), Vector2(648, 0), Vector2(665, 0)]
var level: Node3D
var rng := RandomNumberGenerator.new()
var bark: StandardMaterial3D
var rock: StandardMaterial3D
var snow: StandardMaterial3D
var timber: StandardMaterial3D
var iron: StandardMaterial3D
var wheel: Node3D
var mill_light: OmniLight3D

static func height_at(x: float) -> float:
	for i in PROFILE.size() - 1:
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[i + 1]
		if x >= a.x and x <= b.x: return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return 0

func mat(color: Color, textured := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.97
	if textured:
		var noise := FastNoiseLite.new()
		noise.seed = 91
		noise.frequency = 0.08
		var texture := NoiseTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.noise = noise
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.55, 0.55, 0.55))
		ramp.set_color(1, Color(0.85, 0.85, 0.85))
		texture.color_ramp = ramp
		m.albedo_texture = texture
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.6, 0.6, 0.6)
	return m

func mesh_at(mesh: Mesh, material: Material, pos: Vector3) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	n.visibility_range_end = 85
	n.visibility_range_end_margin = 12
	add_child(n)
	return n

func block(pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh_at(b, material, pos)

func beam(a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius * 0.8
	c.bottom_radius = radius
	c.height = a.distance_to(b)
	c.radial_segments = 7
	var n := mesh_at(c, material, (a + b) / 2)
	n.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	return n

func build(host: Node3D) -> void:
	level = host
	rng.seed = 628
	bark = mat(Color(0.12, 0.095, 0.08), true)
	rock = mat(Color(0.32, 0.35, 0.36), true)
	snow = mat(Color(0.68, 0.73, 0.75), true)
	timber = mat(Color(0.24, 0.17, 0.11), true)
	iron = mat(Color(0.12, 0.14, 0.15))
	terrain()
	forest()
	landmarks()

func terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var zs := [-32.0, -18.0, -9.0, -4.0, -1.2, 1.2, 3.0, 7.0]
	for xi in range(-12, 665):
		if xi >= 248 and xi < 258: continue
		for zi in zs.size() - 1:
			var pts := []
			for corner in [Vector2(xi, zs[zi]), Vector2(xi + 1, zs[zi]), Vector2(xi + 1, zs[zi + 1]), Vector2(xi, zs[zi + 1])]:
				var off := 0.0
				if corner.y < -1.2:
					off = (sin(corner.x * 0.13 + corner.y * 0.3) * 1.2 + cos(corner.x * 0.07) * 1.8) * minf(1, (-corner.y - 1.2) / 6)
				elif corner.y > 1.2: off = -(corner.y - 1.2) * 0.7
				pts.append(Vector3(corner.x, height_at(corner.x) + off, corner.y))
			for index in [0, 1, 2, 0, 2, 3]:
				var v: Vector3 = pts[index]
				var shade := 0.82 + 0.13 * sin(v.x * 2.7 + v.z * 1.9)
				st.set_color(Color(shade, shade, shade))
				st.add_vertex(v)
				if zi == 4: faces.append(v)
	st.generate_normals()
	var m := snow.duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	mesh_at(st.commit(), m, Vector3.ZERO).visibility_range_end = 0
	var body := StaticBody3D.new()
	body.collision_layer = 9
	var shape := CollisionShape3D.new()
	var collision := ConcavePolygonShape3D.new()
	collision.backface_collision = true
	collision.set_faces(faces)
	shape.shape = collision
	body.add_child(shape)
	add_child(body)
	# Köprünün altındaki kanyon: patikadan aşağıya inen iki kaya yüzü.
	for x in [247.5, 258.5]:
		block(Vector3(x, -5.5, -1), Vector3(1, 11, 7), rock)
	var water := mat(Color(0.12, 0.23, 0.26))
	water.metallic = 0.25
	water.roughness = 0.28
	block(Vector3(253, -7, -8), Vector3(10, 0.1, 35), water)

func sprite(kind: String, pos: Vector3, h: float, tint: Color) -> void:
	var s := Sprite3D.new()
	s.texture = load("res://assets/cevre/%s.png" % kind)
	s.pixel_size = h / s.texture.get_height()
	s.position = pos + Vector3(0, h / 2, 0)
	s.modulate = tint
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.no_depth_test = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.visibility_range_end = 100
	add_child(s)

func forest() -> void:
	for layer in 3:
		var x := -12.0
		while x < 665:
			x += rng.randf_range(3.5, 7) + layer
			var z := -6.0 - layer * 9 - rng.randf_range(0, 3)
			if (x > 137 and x < 165) or (x > 246 and x < 260): continue
			sprite(["agac_ince", "agac_olu", "agac_kuru_cam"][rng.randi_range(0, 2)], Vector3(x, height_at(x) - 1, z), rng.randf_range(10, 19), Color(0.32, 0.35, 0.37))
	for i in 95:
		var x := rng.randf_range(-8, 660)
		if x > 247 and x < 259: continue
		var z := rng.randf_range(-4, -2)
		var base := Vector3(x, height_at(x) - 0.3, z)
		var h := rng.randf_range(8, 14)
		beam(base, base + Vector3(rng.randf_range(-0.8, 0.8), h, 0), rng.randf_range(0.12, 0.24), bark)
		beam(base + Vector3(0, h * 0.65, 0), base + Vector3(1.8, h * 0.8, 0.3), 0.055, bark)
	for i in 85:
		var x := rng.randf_range(-4, 660)
		if x > 246 and x < 260: continue
		sprite("kaya_orta", Vector3(x, height_at(x) - 0.1, -2.4), rng.randf_range(0.6, 1.8), Color(0.65, 0.69, 0.72))
	# Ön planda seyrek koyu gövdeler: oyuncunun yolunu kapatmaz.
	for x in [18, 88, 180, 278, 380, 481, 607]:
		beam(Vector3(x, height_at(x) - 2, 4), Vector3(x - 0.7, height_at(x) + 15, 4), 0.33, bark)

func lantern(pos: Vector3) -> void:
	beam(pos, pos + Vector3(0, 2.4, 0), 0.045, iron)
	var glow := mat(Color(1, 0.5, 0.16))
	glow.emission_enabled = true
	glow.emission = Color(1, 0.36, 0.08)
	glow.emission_energy_multiplier = 2
	block(pos + Vector3(0, 2.2, 0), Vector3(0.18, 0.32, 0.18), glow)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 2.2, 0)
	light.light_color = Color(1, 0.58, 0.27)
	light.light_energy = 1.4
	light.omni_range = 6
	add_child(light)

func cabin(x: float, width: float, ruined := false) -> void:
	var y := height_at(x)
	block(Vector3(x, y + 2, -4.5), Vector3(width, 4, 0.35), timber)
	for side in [-1, 1]:
		var roof := block(Vector3(x + side * width / 4, y + 4.3, -3), Vector3(width * 0.58, 0.2, 4.6), bark)
		roof.rotation.z = -side * 0.42
		var cap := block(roof.position + Vector3(0, 0.14, 0), Vector3(width * 0.58, 0.1, 4.6), snow)
		cap.rotation.z = roof.rotation.z
		beam(Vector3(x + side * width / 2, y, -1.5), Vector3(x + side * width / 2, y + 3.4, -1.5), 0.13, timber)
	for k in 7:
		beam(Vector3(x - width / 2, y + k * 0.52, -4.2), Vector3(x + width / 2, y + k * 0.52, -4.2), 0.16, timber)
	block(Vector3(x, y + 1.8, -4.15), Vector3(1.1, 1.3, 0.08), iron)
	if ruined:
		beam(Vector3(x - width / 2, y + 3.2, -1.5), Vector3(x + 1, y + 0.4, -1), 0.13, timber)
	else: lantern(Vector3(x + width / 2 - 0.5, y, -2))

func landmarks() -> void:
	# Açılış: kar yamacı, kurdeleler, düşmüş gövde ve eski yol korkuluğu.
	for x in [25, 34, 42]:
		var y := height_at(x)
		beam(Vector3(x, y, -1.7), Vector3(x, y + 1, -1.7), 0.07, timber)
	beam(Vector3(25, height_at(25) + 0.8, -1.7), Vector3(42, height_at(42) + 0.8, -1.7), 0.045, timber)
	beam(Vector3(47, height_at(47) + 0.3, -3), Vector3(54, height_at(54) + 0.2, -2), 0.32, bark)
	lantern(Vector3(65, 0, -2))
	# Değirmen: gerçek kirişler ve arka duvar; Çınar alt kanaldan geçer.
	cabin(153, 15)
	wheel = Node3D.new()
	wheel.position = Vector3(146, 2.5, -1)
	add_child(wheel)
	for i in 12:
		var angle := i * TAU / 12
		var a := Vector3(cos(angle), sin(angle), 0) * 2
		var b := Vector3(cos(angle + TAU / 12), sin(angle + TAU / 12), 0) * 2
		var spoke := beam(wheel.position, wheel.position + a, 0.06, timber)
		spoke.reparent(wheel)
		var rim := beam(wheel.position + a, wheel.position + b, 0.14, timber)
		rim.reparent(wheel)
	# Kanyon: iki kıyıda çark iskeleleri ve halat askıları.
	for x in [242, 263]:
		for z in [-1.2, 1.2]:
			beam(Vector3(x, 0, z), Vector3(x, 3, z), 0.12, timber)
		lantern(Vector3(x, 0, -2))
	for z in [-1.2, 1.2]:
		beam(Vector3(242, 2.5, z), Vector3(253, 1.3, z), 0.022, iron).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam(Vector3(253, 1.3, z), Vector3(263, 2.5, z), 0.022, iron).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Fener avlusu: yıkılmış kemerin iki ayağı ve taş döşeme.
	for x in [336, 359]:
		for i in 6: block(Vector3(x, i * 0.5 + 0.25, -2), Vector3(1.3, 0.46, 1.3), rock)
	for i in 9: block(Vector3(337 + i * 2.5, -0.03, -0.2), Vector3(2.3, 0.12, 2.7), rock)
	lantern(Vector3(338, 0, -1.8))
	# Yük deposu ve vinç silueti.
	cabin(444, 20, true)
	beam(Vector3(451, 0, -2), Vector3(451, 6, -2), 0.23, timber)
	beam(Vector3(446, 5.5, -2), Vector3(458, 5.5, -2), 0.19, timber)
	beam(Vector3(451, 3.5, -2), Vector3(455, 5.5, -2), 0.12, timber)
	beam(Vector3(455, 5.5, -2), Vector3(455, 1, -2), 0.025, iron).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Köy: yakınlaşırken görülen çatı ve pencere katmanları.
	for x in [551, 568, 589, 612, 630, 650]: cabin(x, 8, x == 589)
	for x in [550, 575, 603, 642]: lantern(Vector3(x, height_at(x), -2))
	var red := mat(Color(0.5, 0.045, 0.025))
	for x in [8, 45, 130, 233, 326, 423, 543]:
		var y := height_at(x)
		beam(Vector3(x, y, -1.8), Vector3(x, y + 1.5, -1.8), 0.05, timber)
		block(Vector3(x + 0.2, y + 1.25, -1.8), Vector3(0.5, 0.12, 0.025), red)

func _process(dt: float) -> void:
	if wheel != null and level.phase == "play":
		wheel.rotation.z -= dt * (0.12 if level.solved[1] else 0.02)
