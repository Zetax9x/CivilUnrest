extends "res://scripts/art_tests/art_batch_builder.gd"
## Independent art diorama. All dimensions are metres; no navigation or simulation.
func _ready() -> void:
	piece("dark_stone", Vector3(0, -0.25, 3), Vector3(32, 0.5, 27))
	piece("asphalt", Vector3(0, 0.015, 9.5), Vector3(31.8, 0.07, 8.6))
	piece("paving", Vector3(0, 0.10, 2.5), Vector3(31.8, 0.20, 5.4))
	piece("paving", Vector3(0, 0.1, 15.35), Vector3(31.8, 0.20, 2.7))
	for z in [5.15, 14.0]:
		for tile in range(40):
			piece("limestone", Vector3(-15.6 + tile * 0.8, 0.12, z), Vector3(0.77, 0.24, 0.30))
	for x in range(32):
		for z in [0.6, 1.65, 2.7, 3.75, 4.75, 14.5, 15.5, 16.3]:
			piece("dark_stone", Vector3(-15.5 + x, 0.205, z), Vector3(0.018, 0.009, 0.98))
	for z in [0.1, 1.15, 2.2, 3.25, 4.3, 14.4, 15.4, 16.4]:
		piece("dark_stone", Vector3(0, 0.205, z), Vector3(31.7, 0.009, 0.018))
	for x in range(-14, 15, 4):
		piece("paint", Vector3(x, 0.058, 9.5), Vector3(1.9, 0.008, 0.10))
	for x in range(7):
		piece("paint", Vector3(-9.5, 0.059, 6.1 + x * 1.08), Vector3(2.3, 0.008, 0.48))
	for x in [-1.5, 5.0, 11.5]:
		for side in [-1.0, 1.0]:
			piece("paint", Vector3(x + side * 2.5, 0.06, 6.5), Vector3(0.08, 0.008, 2.0))
		piece("paint", Vector3(x, 0.06, 5.55), Vector3(4.9, 0.008, 0.08))
	for point in [Vector3(3, 0.061, 10.8), Vector3(-10, 0.21, 3.5)]:
		piece("iron", point, Vector3(0.72, 0.015, 0.72), "cylinder")
		for rib in range(6):
			piece("dark_stone", point + Vector3(0, 0.01, -0.24 + rib * 0.09), Vector3(0.5, 0.01, 0.022))
	for x in [-13.5, 12.5]:
		street_lamp(Vector3(x, 0.2, 4.35))
		bin_at(Vector3(x + 0.75, 0.2, 4.2))
	for x in [-11.5, -7, -2, 3, 8, 14]:
		piece("iron", Vector3(x, 0.63, 4.55), Vector3(0.13, 0.86, 0.13), "cylinder")
		piece("chrome", Vector3(x, 0.97, 4.55), Vector3(0.14, 0.05, 0.14), "cylinder")
	for point in [Vector3(-11.8, 0.2, 1.4), Vector3(12, 0.2, 1.4)]:
		planter(point)
	for x in [-11, 11]:
		piece("terracotta", Vector3(x, 0.48, 0.1), Vector3(0.9, 0.6, 0.9))
		piece("soil", Vector3(x, 0.80, 0.1), Vector3(0.78, 0.02, 0.78))
		for leaf in range(5):
			piece("leaves", Vector3(x + sin(leaf * 2.0) * 0.2, 1.0, 0.1 + cos(leaf * 2.0) * 0.2), Vector3(0.20, 0.7, 0.20), "sphere", Vector3(0.2, leaf, 0.3))
	flush()

func street_lamp(point: Vector3) -> void:
	piece("iron", point + Vector3(0, 0.14, 0), Vector3(0.38, 0.28, 0.38), "cylinder")
	piece("iron", point + Vector3(0, 2.5, 0), Vector3(0.11, 5.0, 0.11), "cylinder")
	beam("iron", point + Vector3(0, 4.9, 0), point + Vector3(0, 5.15, 0.7), 0.10)
	piece("iron", point + Vector3(0, 5.15, 0.85), Vector3(0.28, 0.12, 0.68))
	piece("glass", point + Vector3(0, 5.08, 0.9), Vector3(0.21, 0.03, 0.48))

func bin_at(point: Vector3) -> void:
	piece("iron", point + Vector3(0, 0.47, 0), Vector3(0.50, 0.94, 0.50), "cylinder")
	piece("dark_stone", point + Vector3(0, 0.94, 0), Vector3(0.54, 0.08, 0.54), "cylinder")
	for rib in range(12):
		var angle := rib * TAU / 12
		piece("chrome", point + Vector3(cos(angle) * 0.25, 0.48, sin(angle) * 0.25), Vector3(0.015, 0.72, 0.015))

func planter(point: Vector3) -> void:
	piece("dark_stone", point + Vector3(0, 0.2, 0), Vector3(1.6, 0.4, 1.6))
	piece("soil", point + Vector3(0, 0.41, 0), Vector3(1.4, 0.03, 1.4))
	piece("wood", point + Vector3(0, 1.65, 0), Vector3(0.22, 2.5, 0.22), "cylinder")
	for branch in range(5):
		var offset := Vector3(sin(branch * 2.4) * 0.6, 3.0 + branch * 0.17, cos(branch * 2.4) * 0.55)
		beam("wood", point + Vector3(0, 2.2, 0), point + offset, 0.08)
		piece("leaves" if branch % 2 == 0 else "leaf_light", point + offset, Vector3(1.65, 1.7, 1.65), "sphere")
