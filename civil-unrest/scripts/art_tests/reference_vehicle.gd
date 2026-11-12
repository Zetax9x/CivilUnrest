extends "res://scripts/art_tests/art_batch_builder.gd"
@export var police: bool = false

func _ready() -> void:
	var paint := "police_white" if police else "car_sage"
	var length_scale: float = 1.12 if police else 1.0
	# Tapered body and cabin are designed profiles; no branded model is reproduced.
	prism("body", PackedVector2Array([Vector2(-2.12, 0.42), Vector2(-2.15, 0.66), Vector2(-1.8, 0.90), Vector2(1.65, 0.94), Vector2(2.1, 0.72), Vector2(2.0, 0.42)]), 1.73)
	prism("cabin", PackedVector2Array([Vector2(-0.97, 0.91), Vector2(-0.44, 1.48), Vector2(0.76, 1.48), Vector2(1.44, 0.94)]), 1.47)
	piece(paint, Vector3.ZERO, Vector3(length_scale, 1, 1), "body")
	piece("glass", Vector3(0, 0, 0), Vector3(length_scale, 1, 1), "cabin")
	piece(paint, Vector3(0.16, 1.50, 0), Vector3(1.28 * length_scale, 0.08, 1.5))
	for z in [-0.76, 0.76]:
		piece(paint, Vector3(0.10, 1.20, z), Vector3(0.09, 0.58, 0.065))
		piece(paint, Vector3(-0.67, 1.22, z), Vector3(0.075, 0.76, 0.06), "box", Vector3(0, 0, -0.72))
		piece(paint, Vector3(1.07, 1.19, z), Vector3(0.075, 0.84, 0.06), "box", Vector3(0, 0, 0.90))
		piece("iron", Vector3(0.1, 0.96, z), Vector3(2.36, 0.05, 0.07))
		piece("chrome", Vector3(0.4, 0.91, z * 1.16), Vector3(0.24, 0.04, 0.035))
		piece("iron", Vector3(-0.8, 1.08, z * 1.18), Vector3(0.24, 0.13, 0.20), "sphere")
		if police:
			piece("police_blue", Vector3(0, 0.76, z * 1.15), Vector3(3.86, 0.25, 0.035))
	for x in [-1.28, 1.28]:
		for z in [-0.87, 0.87]:
			piece("rubber", Vector3(x * length_scale, 0.38, z), Vector3(0.69, 0.24, 0.69), "cylinder", Vector3(PI / 2, 0, 0))
			piece("chrome", Vector3(x * length_scale, 0.38, z * 1.145), Vector3(0.41, 0.025, 0.41), "cylinder", Vector3(PI / 2, 0, 0))
	for x in [-2.10, 2.04]:
		piece("iron", Vector3(x * length_scale, 0.52, 0), Vector3(0.10, 0.13, 1.48))
		piece("chrome", Vector3(x * length_scale, 0.70, 0), Vector3(0.025, 0.11, 0.45))
		for z in [-0.58, 0.58]:
			piece("paint" if x < 0 else "terracotta", Vector3(x * length_scale, 0.74, z), Vector3(0.045, 0.17, 0.31))
	if police:
		piece("iron", Vector3(0.08, 1.61, 0), Vector3(0.48, 0.09, 1.14))
		for z in [-0.42, 0.42]:
			piece("police_blue", Vector3(0.08, 1.71, z), Vector3(0.32, 0.16, 0.31))
		label_text("POLIZIA", Vector3(0.18, 0.78, 0.895), 0.18, Color("#d3d9d5"))
		label_text("POLIZIA", Vector3(0.18, 0.78, -0.895), 0.18, Color("#d3d9d5"), PI)
	flush()
