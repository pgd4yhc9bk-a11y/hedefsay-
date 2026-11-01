class_name ProtoTutorial extends Control
## Uygulamalı öğretici: o an ne yapılması gerekiyorsa ekranda gösterir. Dokunmatikte kayan bir parmak (iz bırakır),
## klavyede basılan tuş. Oyuncu hareketi yapınca adım kapanır ve bir daha çıkmaz.
## Adımlar: yürü, kütüğe tırman, uçurumdan atla, kasayı it, kasaya çık ve duvara tırman.

var touch := true
var step := ""                 # şu an gösterilen adım
var extra := ""                # yazının sonuna eklenen ilerleme (ör. "1 / 3")
var done := {}
var _u := 0.0
var _a := 0.0                  # görünürlük
var finger: TextureRect
var ring: TextureRect
var trail: Line2D
var label: Label
var keys: Array[Panel] = []
var key_lbl: Array[Label] = []

const STEPS := {
	"walk": {"g": "walk", "t": "Parmağını sağa kaydır ve basılı tut: yürü", "k": ["→"], "kt": "Yürümek için → tuşuna bas"},
	"log": {"g": "up", "t": "Kütüğe gelince yukarı kaydır: üstünden geç", "k": ["↑"], "kt": "Kütükten geçmek için ↑"},
	"gap": {"g": "runjump", "t": "Koşarken yukarı kaydır: boşluğun üstünden atla", "k": ["→", "↑"], "kt": "Koşarken ↑ ile atla"},
	"push": {"g": "push", "t": "Kasaya doğru kaydırıp basılı tut: it", "k": ["→"], "kt": "Kasayı itmek için → tuşunu basılı tut"},
	"climb": {"g": "up", "t": "Kasanın dibinde yukarı kaydır: çık, sonra duvara tırman", "k": ["↑"], "kt": "Kasaya ve duvara çıkmak için ↑"},
	"wheel": {"g": "circle", "t": "Çarkın yanında, ekranın sağında saat yönünde 3 tur çevir", "k": ["E"], "kt": "Çarkın yanında E tuşunu basılı tut: çevir"},
	"boat": {"g": "walk", "t": "Sandala bin, sağa kaydırıp basılı tut: halatı çekerek karşıya geç", "k": ["→"], "kt": "Sandalda → basılı tut: halatı çek"},
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280, 720)
	touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.get_environment("TUTTOUCH") != ""
	trail = Line2D.new()
	trail.width = 18.0
	trail.default_color = Color(1, 1, 1, 0.3)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var wc := Curve.new()
	wc.add_point(Vector2(0, 0.2))
	wc.add_point(Vector2(1, 1))
	trail.width_curve = wc
	add_child(trail)
	ring = TextureRect.new()
	ring.texture = _disc(96, true)
	ring.size = Vector2(96, 96)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	finger = TextureRect.new()
	finger.texture = _disc(80, false)
	finger.size = Vector2(80, 80)
	finger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(finger)
	for i in 2:
		var p := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.08)
		sb.border_color = Color(1, 1, 1, 0.7)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		p.add_theme_stylebox_override("panel", sb)
		p.size = Vector2(64, 64)
		p.pivot_offset = Vector2(32, 32)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		var l := Label.new()
		l.size = Vector2(64, 64)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 30)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
		keys.append(p)
		key_lbl.append(l)
	label = Label.new()
	label.position = Vector2(0, 628)
	label.size = Vector2(1280, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.88))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	modulate.a = 0.0

func _disc(n: int, hollow: bool) -> Texture2D:
	var g := Gradient.new()
	if hollow:   # parmağın dokunduğu yerde yayılan halka
		g.offsets = PackedFloat32Array([0.0, 0.62, 0.72, 0.82, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0), Color(1, 1, 1, 0)])
	else:        # parmak ucu: dolu, yumuşak kenarlı
		g.offsets = PackedFloat32Array([0.0, 0.6, 0.8, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = n
	gt.height = n
	return gt

## Her kare: hangi adımın gösterileceğine oyun karar verir (want); "" = hiçbiri.
func show_step(want: String, dt: float) -> void:
	if want != "" and done.has(want):
		want = ""
	if want != step:
		if _a <= 0.01:   # önceki söndükten sonra yenisi
			step = want
			_u = 0.0
		else:
			want = ""
	_a = move_toward(_a, 1.0 if want != "" and want == step else 0.0, dt * 2.5)
	modulate.a = _a
	if step == "":
		return
	var s: Dictionary = STEPS[step]
	label.text = (s["t"] if touch else s["kt"]) + extra
	_u = fmod(_u + dt / 1.8, 1.0)
	finger.visible = touch
	ring.visible = touch
	trail.visible = touch
	for i in 2:
		keys[i].visible = not touch and i < (s["k"] as Array).size()
	if touch:
		_gesture(s["g"])
	else:
		_keys(s["k"])

func finish(id: String) -> void:
	done[id] = true

func _gesture(g: String) -> void:
	var c := Vector2(640, 540)
	var u := _u
	var p := c
	var pts := PackedVector2Array()
	var press := 0.0
	var fa := clampf(u / 0.08, 0.0, 1.0) * clampf((1.0 - u) / 0.12, 0.0, 1.0)   # parmak belir/sön
	match g:
		"walk", "push":   # bas, sağa kaydır, basılı tut
			var k := _ease(clampf((u - 0.1) / 0.45, 0.0, 1.0))
			var a := c + Vector2(-150, 0)
			var b := c + Vector2(110, 0)
			p = a.lerp(b, k)
			if g == "push" and u > 0.55:
				p += Vector2(sin(u * 60.0) * 3.0, 0)   # kasaya yüklenme
			pts = PackedVector2Array([a, p])
			press = 1.0 - clampf((u - 0.05) / 0.1, 0.0, 1.0) * 0.6
		"up":   # hızlı yukarı fiske
			var k := _ease(clampf((u - 0.15) / 0.2, 0.0, 1.0))
			var a := c + Vector2(0, 50)
			var b := c + Vector2(0, -110)
			p = a.lerp(b, k)
			pts = PackedVector2Array([a, p]) if k > 0.0 else PackedVector2Array()
			press = 1.0 - clampf((u - 0.1) / 0.1, 0.0, 1.0) * 0.6
		"circle":   # ekranın sağında saat yönünde daire
			var cc := Vector2(990, 390)
			var r := 95.0
			var k := clampf((u - 0.05) / 0.85, 0.0, 1.0)
			var a0 := -PI / 2.0
			p = cc + Vector2(cos(a0 + k * TAU), sin(a0 + k * TAU)) * r
			var nn := 24
			for i in nn + 1:
				var aa := a0 + k * TAU * float(i) / nn
				pts.append(cc + Vector2(cos(aa), sin(aa)) * r)
			press = 1.0 - clampf((u - 0.05) / 0.1, 0.0, 1.0) * 0.6
		"runjump":   # sağa kaydır, sonra yukarı fiske
			var a := c + Vector2(-170, 40)
			var m := c + Vector2(40, 40)
			var b := c + Vector2(110, -90)
			var k1 := _ease(clampf((u - 0.08) / 0.4, 0.0, 1.0))
			var k2 := _ease(clampf((u - 0.5) / 0.15, 0.0, 1.0))
			p = a.lerp(m, k1) if k2 <= 0.0 else m.lerp(b, k2)
			pts = PackedVector2Array([a, m if k2 > 0.0 else p])
			if k2 > 0.0:
				pts.append(p)
			press = 1.0 - clampf((u - 0.05) / 0.1, 0.0, 1.0) * 0.6
	finger.position = p - finger.size * 0.5
	finger.modulate.a = fa
	finger.scale = Vector2.ONE * (0.85 + 0.15 * (1.0 - press))
	finger.pivot_offset = finger.size * 0.5
	# dokunma anında yayılan halka
	var rk := clampf((u - 0.03) / 0.3, 0.0, 1.0)
	ring.pivot_offset = ring.size * 0.5
	ring.scale = Vector2.ONE * lerpf(0.4, 1.3, rk)
	ring.modulate.a = (1.0 - rk) * fa
	ring.position = (pts[0] if pts.size() > 0 else p) - ring.size * 0.5
	trail.points = pts
	trail.modulate.a = fa

func _keys(ks: Array) -> void:
	var n := ks.size()
	for i in n:
		var p := keys[i]
		key_lbl[i].text = ks[i]
		p.position = Vector2(640 - n * 40 + i * 80, 540)
		# sırayla basılır: tuş küçülür ve parlar
		var ph := fmod(_u * 2.0 - i * 0.35, 2.0)
		var pr := 1.0 if ph > 0.0 and ph < 0.35 else 0.0
		p.scale = Vector2.ONE * (1.0 - 0.12 * pr)
		(p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(1, 1, 1, 0.08 + 0.3 * pr)

func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
