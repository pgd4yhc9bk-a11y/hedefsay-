class_name Levels
## Bölüm verileri (JavaScript prototipiyle aynı sayılar). Koordinatlar piksel, sol üst köşe.

const GY := 560.0

static func all() -> Array:
	var gy := GY
	return [
		{
			"name": "Sis", "w": 2700.0, "start": Vector2(60, gy - 54), "hint": "",
			"statics": [Rect2(0, gy, 800, 160), Rect2(870, gy, 630, 160), Rect2(1100, 500, 60, 60), Rect2(1500, 430, 400, 290), Rect2(1900, gy, 800, 160)],
			"crates": [Vector2(1250, gy - 56)], "mask": {}, "plates": [], "doors": [],
			"spikes": [Rect2(2000, gy - 24, 48, 24)], "saws": [], "darts": [], "water": [],
			"checkpoints": [900.0, 1950.0], "exit": Rect2(2550, gy - 100, 70, 100),
		},
		{
			"name": "Ağırlık", "w": 2500.0, "start": Vector2(60, gy - 54), "hint": "",
			"statics": [Rect2(0, gy, 1500, 160), Rect2(1570, gy, 340, 160), Rect2(1910, 430, 590, 290)],
			"crates": [Vector2(300, gy - 56), Vector2(1700, gy - 56)], "mask": {},
			"plates": [{"rect": Rect2(700, gy - 8, 90, 8), "door": 0, "heavy": false}], "doors": [Rect2(1000, 300, 30, 260)],
			"spikes": [], "saws": [], "darts": [], "water": [],
			"checkpoints": [1060.0, 1650.0], "exit": Rect2(2300, 330, 70, 100),
		},
		{
			"name": "Testere", "w": 2800.0, "start": Vector2(60, gy - 54), "hint": "Testere yukarı çıkınca altından geç",
			"statics": [Rect2(0, gy, 700, 160), Rect2(770, gy, 950, 160), Rect2(1790, gy, 1010, 160)],
			"crates": [Vector2(1860, gy - 56)], "mask": {},
			"plates": [{"rect": Rect2(2020, gy - 8, 90, 8), "door": 0, "heavy": false}], "doors": [Rect2(2330, 300, 30, 260)],
			"spikes": [Rect2(1000, gy - 24, 48, 24), Rect2(2190, gy - 24, 48, 24)],
			"saws": [{"x1": 1400.0, "x2": 1400.0, "y1": gy - 22, "y2": gy - 160, "r": 26.0, "period": 2.8}], "darts": [], "water": [],
			"checkpoints": [850.0, 1850.0], "exit": Rect2(2650, gy - 100, 70, 100),
		},
		{
			"name": "Kabuk", "w": 2000.0, "start": Vector2(60, gy - 54), "hint": "Q / 🎭: maskeyi al · tekrar bas: fırlat · maske ağırdır, düğmeye basar",
			"statics": [Rect2(0, gy, 1300, 160), Rect2(1370, gy, 630, 160)],
			"crates": [], "mask": {"pos": Vector2(190, gy - 68)},
			"plates": [{"rect": Rect2(560, gy - 8, 90, 8), "door": 0, "heavy": true}], "doors": [Rect2(820, 300, 30, 260)],
			"spikes": [], "saws": [], "darts": [], "water": [],
			"checkpoints": [900.0, 1420.0], "exit": Rect2(1850, gy - 100, 70, 100),
		},
		{
			"name": "Kalkan", "w": 2300.0, "start": Vector2(60, gy - 54), "hint": "Maske takılıyken oklara dön: kalkan olur. Çıkarırsan siper veya basamak olur",
			"statics": [Rect2(0, gy, 2300, 160), Rect2(1750, 420, 550, 300)],
			"crates": [], "mask": {"worn": true}, "plates": [], "doors": [],
			"spikes": [], "saws": [], "water": [],
			"darts": [{"x": 1746.0, "y": gy - 30, "dir": -1, "every": 1.7, "phase": 0.4}, {"x": 1746.0, "y": gy - 46, "dir": -1, "every": 1.7, "phase": 1.25}],
			"checkpoints": [900.0, 1450.0], "exit": Rect2(2100, 320, 70, 100),
		},
		{
			"name": "Sular", "w": 2100.0, "start": Vector2(60, gy - 54), "hint": "Maske suda yüzer: fırlat, üstüne çık, karşıya geç",
			"statics": [Rect2(0, gy, 700, 160), Rect2(870, gy, 1230, 160), Rect2(1560, 430, 540, 290)],
			"water": [Rect2(700, gy + 8, 170, 160)], "mask": {"pos": Vector2(300, gy - 68)}, "crates": [Vector2(1150, gy - 56)],
			"plates": [], "doors": [], "spikes": [], "saws": [], "darts": [],
			"checkpoints": [920.0], "exit": Rect2(1950, 330, 70, 100),
		},
		{
			"name": "Fener", "coop": true, "dark": true, "w": 2600.0, "start": Vector2(60, gy - 54), "start2": Vector2(100, gy - 54),
			"hint": "Kül ışığıyla yolu açar. Kül ortada durmalı: ışık değen platformlar katıdır",
			"statics": [Rect2(0, gy, 1000, 160), Rect2(1560, gy, 1040, 160)],
			"ghosts": [Rect2(1070, 530, 90, 16), Rect2(1230, 520, 90, 16), Rect2(1390, 530, 90, 16)],
			"crates": [], "mask": {}, "plates": [], "doors": [], "spikes": [], "saws": [], "darts": [], "water": [],
			"checkpoints": [900.0, 1600.0], "exit": Rect2(2450, gy - 100, 70, 100),
		},
		{
			"name": "Siper", "coop": true, "dark": true, "w": 2300.0, "start": Vector2(60, gy - 54), "start2": Vector2(20, gy - 54),
			"hint": "Kabuk kalkanla önde yürür, Kül arkasından ışık tutar. Sonra maske basamak olur",
			"statics": [Rect2(0, gy, 2300, 160), Rect2(1750, 420, 550, 300)],
			"crates": [], "mask": {"worn": true}, "plates": [], "doors": [], "spikes": [], "saws": [], "water": [],
			"darts": [{"x": 1746.0, "y": gy - 30, "dir": -1, "every": 1.7, "phase": 0.4}, {"x": 1746.0, "y": gy - 46, "dir": -1, "every": 1.7, "phase": 1.25}],
			"checkpoints": [900.0, 1450.0], "exit": Rect2(2100, 320, 70, 100),
		},
	]
