extends "res://scripts/camera/isometric_camera.gd"
func reset_view() -> void:
	super.reset_view()
	position = Vector3(0,1.0,0)
