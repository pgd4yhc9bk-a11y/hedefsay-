class_name Cinematic extends RefCounted
## Oyun içi ara sahne: kamera anahtar kareleri (konum, bakış noktası, görüş açısı) + zamanlı olaylar.
## Kamera kareler arasında yumuşak (Catmull-Rom) bir yol izler; olaylar zamanı gelince bir kez çalışır.
## Kullanım:
##   var c := Cinematic.new()
##   c.cam(0.0, pos, look, 30.0); c.cam(3.0, ...)
##   c.at(1.5, func(): ...)
##   her kare: c.step(dt) ; kamera için c.pose() -> {pos, look, fov}

var t := 0.0
var length := 0.0
var keys: Array = []      # [zaman, konum, bakış, fov]
var events: Array = []    # [zaman, Callable, çalıştı mı]

func cam(time: float, pos: Vector3, look: Vector3, fov := 30.0) -> Cinematic:
	keys.append([time, pos, look, fov])
	length = maxf(length, time)
	return self

func at(time: float, f: Callable) -> Cinematic:
	events.append([time, f, false])
	length = maxf(length, time)
	return self

func step(dt: float) -> void:
	t += dt
	for e: Array in events:
		if not e[2] and t >= float(e[0]):
			e[2] = true
			(e[1] as Callable).call()

func done() -> bool:
	return t >= length

## Şu anki kamera: {pos, look, fov}
func pose() -> Dictionary:
	if keys.is_empty():
		return {}
	if t <= float(keys[0][0]):
		return {"pos": keys[0][1], "look": keys[0][2], "fov": keys[0][3]}
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if t <= float(b[0]):
			var u := (t - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			u = u * u * (3.0 - 2.0 * u)   # her kareye yumuşak giriş-çıkış
			var p0: Array = keys[maxi(i - 1, 0)]
			var p3: Array = keys[mini(i + 2, keys.size() - 1)]
			return {
				"pos": _cr(p0[1], a[1], b[1], p3[1], u),
				"look": _cr(p0[2], a[2], b[2], p3[2], u),
				"fov": lerpf(a[3], b[3], u),
			}
	var l: Array = keys[keys.size() - 1]
	return {"pos": l[1], "look": l[2], "fov": l[3]}

func _cr(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	# Catmull-Rom: kareler arasında kırılmasız yol
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)
