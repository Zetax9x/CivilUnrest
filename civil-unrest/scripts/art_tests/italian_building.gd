extends "res://scripts/art_tests/art_batch_builder.gd"
## Original four-storey corner palazzo: reusable front/side bays and balcony modules.
const FLOOR_HEIGHT: float = 3.05
const FRONT: float = 4.5

func _ready() -> void:
	# Deep core stops behind the true window recesses; facade strips surround openings.
	piece("plaster_ochre", Vector3(0, 6.4, -0.20), Vector3(15.8, 12.8, 8.7))
	for level in range(4):
		var base := 0.2 + level * FLOOR_HEIGHT
		var wall_material := "limestone" if level == 0 else "plaster_ochre"
		for bay in range(5):
			var x := -6.4 + bay * 3.2
			front_bay(x, base, level, wall_material, bay)
		# Articulated right side, visible at the initial 45-degree yaw.
		for bay in range(3):
			side_bay(-3.0 + bay * 3.0, base, level, wall_material)
		for y in [base + 0.12, base + FLOOR_HEIGHT - 0.08]:
			piece("limestone", Vector3(0, y, FRONT + 0.12), Vector3(16.35, 0.12, 0.32))
			piece("limestone", Vector3(8.06, y, 0), Vector3(0.32, 0.12, 9.2))
	# Quoin blocks and a projecting central pilaster give the facade depth.
	for y in range(20):
		for x in [-7.85, 7.85]:
			piece("limestone", Vector3(x, 0.5 + y * 0.62, 4.62), Vector3(0.55 if y % 2 == 0 else 0.76, 0.56, 0.30))
	for x in [-8.0, 8.0]:
		piece("dark_stone", Vector3(x, 0.38, 0), Vector3(0.28, 0.70, 9.4))
	for x in [-3.2, 3.2]:
		piece("plaster_repair", Vector3(x, 7.6, 4.56), Vector3(0.23, 9.2, 0.18))
	for i in range(4):
		piece("limestone", Vector3(0, 12.55 + i * 0.12, 0), Vector3(16.4 + i * 0.16, 0.16, 9.5 + i * 0.16))
	# Shallow pitched roof and inexpensive tile ribs, not a flat placeholder box.
	prism("roof", PackedVector2Array([Vector2(-8.5, 0), Vector2(8.5, 0), Vector2(0, 1.65)]), 9.9)
	piece("terracotta", Vector3(0, 13.05, 0), Vector3.ONE, "roof")
	for tile in range(43):
		var x := -8.4 + tile * 0.4
		var y := 13.075 + 1.65 * (1.0 - absf(x) / 8.5)
		piece("terracotta", Vector3(x, y, 0), Vector3(0.07, 9.9, 0.07), "cylinder", Vector3(PI / 2.0, 0, 0))
	piece("iron", Vector3(0, 12.75, 4.85), Vector3(0.11, 16.8, 0.11), "cylinder", Vector3(0, 0, PI / 2.0))
	for x in [-7.9, 7.9]:
		beam("iron", Vector3(x, 12.7, 4.86), Vector3(x, 0.2, 4.86), 0.10)
		beam("iron", Vector3(x, 0.3, 4.86), Vector3(x, 0.15, 5.05), 0.10)
	for point in [Vector3(-4.5, 14.35, -1.5), Vector3(4.5, 14.35, -2.7)]:
		piece("plaster_repair", point, Vector3(0.65, 1.15, 0.65))
		piece("dark_stone", point + Vector3(0, 0.64, 0), Vector3(0.90, 0.12, 0.9))
	shop()
	flush()

func front_bay(x: float, base: float, level: int, wall: String, bay: int) -> void:
	var width: float = 1.38 if level > 0 else 2.35
	var height: float = 1.95 if level > 0 else 2.45
	var center_y := base + 1.48
	piece(wall, Vector3(x, base + FLOOR_HEIGHT * 0.5, FRONT), Vector3(3.18, FLOOR_HEIGHT, 0.20))
	# Recess reads as shadow, inset reveal and framed glass with actual projecting sill.
	piece("dark_stone", Vector3(x, center_y, 4.62), Vector3(width + 0.2, height + 0.20, 0.08))
	piece("glass", Vector3(x, center_y, 4.68), Vector3(width, height, 0.045))
	for side in [-1.0, 1.0]:
		piece("limestone", Vector3(x + side * (width * 0.5 + 0.10), center_y, 4.76), Vector3(0.14, height + 0.28, 0.28))
	piece("limestone", Vector3(x, center_y + height * 0.5 + 0.12, 4.79), Vector3(width + 0.44, 0.16, 0.35))
	piece("limestone", Vector3(x, center_y - height * 0.5 - 0.05, 4.84), Vector3(width + 0.52, 0.11, 0.48))
	piece("wood", Vector3(x, center_y, 4.73), Vector3(0.055, height, 0.055))
	piece("wood", Vector3(x, center_y + 0.23, 4.73), Vector3(width, 0.05, 0.055))
	if level == 0:
		return
	for side in [-1.0, 1.0]:
		var shutter_x: float = x + side * (width * 0.5 + 0.43)
		piece("shutters", Vector3(shutter_x, center_y, 4.73), Vector3(0.52, height, 0.07), "box", Vector3(0, side * 0.12, 0))
		for slat in range(10):
			piece("iron", Vector3(shutter_x, center_y - 0.85 + slat * 0.18, 4.78), Vector3(0.43, 0.026, 0.035))
	if bay % 2 == 0:
		balcony(x, base + 0.42, level)
	elif level == 2:
		piece("plaster_repair", Vector3(x + 0.95, base + 0.4, 4.62), Vector3(0.32, 0.35, 0.015))

func balcony(x: float, y: float, level: int) -> void:
	piece("limestone", Vector3(x, y, 5.13), Vector3(2.6, 0.18, 1.34))
	piece("dark_stone", Vector3(x, y - 0.1, 5.1), Vector3(2.38, 0.06, 1.2))
	for dx in [-1.20, 1.20]:
		beam("limestone", Vector3(x + dx, y - 0.45, 4.65), Vector3(x + dx, y - 0.06, 5.50), 0.16)
	for rail_y in [y + 0.14, y + 1.07]:
		piece("iron", Vector3(x, rail_y, 5.73), Vector3(2.55, 0.05, 0.05))
		for dx in [-1.25, 1.25]:
			piece("iron", Vector3(x + dx, rail_y, 5.17), Vector3(0.05, 0.05, 1.18))
	for bar in range(11):
		piece("iron", Vector3(x - 1.2 + bar * 0.24, y + 0.6, 5.73), Vector3(0.032, 0.94, 0.032))
	for dx in [-1.25, 1.25]:
		for z in [4.72, 5.20, 5.72]:
			piece("iron", Vector3(x + dx, y + 0.6, z), Vector3(0.032, 0.94, 0.032))
	if level != 2:
		piece("terracotta", Vector3(x + 0.65, y + 0.30, 5.42), Vector3(0.45, 0.35, 0.32))
		for dx in [-0.12, 0.12]:
			piece("leaves", Vector3(x + 0.65 + dx, y + 0.58, 5.42), Vector3(0.36, 0.38, 0.3), "sphere")

func side_bay(z: float, base: float, level: int, wall: String) -> void:
	piece(wall, Vector3(8.0, base + FLOOR_HEIGHT * 0.5, z), Vector3(0.22, FLOOR_HEIGHT, 2.98))
	var y := base + 1.48
	piece("dark_stone", Vector3(8.15, y, z), Vector3(0.05, 2.14, 1.48))
	piece("glass", Vector3(8.19, y, z), Vector3(0.04, 1.93, 1.25))
	for side in [-1.0, 1.0]:
		piece("limestone", Vector3(8.28, y, z + side * 0.73), Vector3(0.28, 2.22, 0.13))
	piece("limestone", Vector3(8.28, y - 1.04, z), Vector3(0.4, 0.11, 1.7))
	piece("limestone", Vector3(8.28, y + 1.12, z), Vector3(0.3, 0.13, 1.68))
	piece("wood", Vector3(8.24, y, z), Vector3(0.04, 1.9, 0.055))
	if level == 0:
		piece("iron", Vector3(8.32, y, z), Vector3(0.05, 0.05, 1.3))

func shop() -> void:
	piece("shutters", Vector3(-3.2, 3.03, 4.95), Vector3(9.5, 0.52, 0.26))
	label_text("ALIMENTARI  /  EMILIA", Vector3(-3.2, 3.03, 5.095), 0.31, Color("#d2c8ac"))
	for x in [-6.4, -3.2, 0.0]:
		piece("shutters", Vector3(x, 2.65, 5.25), Vector3(2.9, 0.13, 1.18), "box", Vector3(-0.16, 0, 0))
		piece("shutters", Vector3(x, 2.48, 5.84), Vector3(2.9, 0.23, 0.055))
		for stripe in range(8):
			piece("limestone", Vector3(x - 1.3 + stripe * 0.37, 2.68, 5.25), Vector3(0.12, 0.015, 1.15), "box", Vector3(-0.16, 0, 0))
		for shelf in range(3):
			piece("wood", Vector3(x, 0.65 + shelf * 0.37, 4.78), Vector3(2.1, 0.045, 0.08))
			for item in range(6):
				piece("terracotta" if item % 2 == 0 else "leaves", Vector3(x - 0.83 + item * 0.33, 0.77 + shelf * 0.37, 4.83), Vector3(0.16, 0.20, 0.11))
	label_text("14", Vector3(7.18, 2.35, 4.86), 0.20, Color("#343e3a"))
	piece("limestone", Vector3(7.18, 2.35, 4.81), Vector3(0.36, 0.34, 0.04))
	piece("iron", Vector3(7.20, 1.45, 4.84), Vector3(0.18, 0.28, 0.06))
