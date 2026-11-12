extends "res://scripts/art_tests/art_batch_builder.gd"
## 1.78 m static reference, approximately 7.5 heads; no physics, rig or crowd logic.
func _ready() -> void:
	# Feet, two separate legs, pelvis, shaped jacket and neck.
	for side in [-1.0, 1.0]:
		piece("rubber", Vector3(side * 0.105, 0.065, 0.045), Vector3(0.135, 0.12, 0.28), "sphere")
		beam("denim", Vector3(side * 0.11, 0.14, 0), Vector3(side * 0.10, 0.53, -0.015), 0.13)
		beam("denim", Vector3(side * 0.10, 0.53, -0.015), Vector3(side * 0.095, 0.93, 0), 0.16)
		piece("denim", Vector3(side * 0.1, 0.53, -0.015), Vector3(0.14, 0.14, 0.14), "sphere")
	piece("denim", Vector3(0, 0.94, 0), Vector3(0.34, 0.21, 0.25), "sphere")
	piece("jacket", Vector3(0, 1.21, -0.005), Vector3(0.43, 0.59, 0.28), "sphere")
	piece("jacket", Vector3(0, 1.05, 0), Vector3(0.32, 0.16, 0.25))
	piece("iron", Vector3(0, 1.20, 0.14), Vector3(0.012, 0.40, 0.012))
	piece("skin", Vector3(0, 1.52, 0), Vector3(0.115, 0.15, 0.12), "cylinder")
	for side in [-1.0, 1.0]:
		piece("jacket", Vector3(side * 0.215, 1.37, 0), Vector3(0.14, 0.17, 0.17), "sphere")
		beam("jacket", Vector3(side * 0.23, 1.36, 0), Vector3(side * 0.28, 1.10, 0.015), 0.13)
		piece("jacket", Vector3(side * 0.28, 1.10, 0.015), Vector3(0.12, 0.12, 0.13), "sphere")
		beam("jacket", Vector3(side * 0.28, 1.10, 0.015), Vector3(side * 0.28, 0.88, 0.065), 0.105)
		piece("skin", Vector3(side * 0.28, 0.83, 0.075), Vector3(0.085, 0.16, 0.07), "sphere")
	piece("skin", Vector3(0, 1.645, 0.015), Vector3(0.205, 0.25, 0.22), "sphere")
	piece("hair", Vector3(0, 1.725, -0.005), Vector3(0.215, 0.105, 0.225), "sphere")
	piece("skin", Vector3(0, 1.64, 0.129), Vector3(0.055, 0.065, 0.05), "sphere")
	for side in [-1.0, 1.0]:
		piece("skin", Vector3(side * 0.104, 1.645, 0.015), Vector3(0.025, 0.06, 0.04), "sphere")
		piece("hair", Vector3(side * 0.042, 1.676, 0.116), Vector3(0.031, 0.008, 0.008))
		piece("iron", Vector3(side * 0.042, 1.657, 0.121), Vector3(0.012, 0.009, 0.005), "sphere")
	flush()
