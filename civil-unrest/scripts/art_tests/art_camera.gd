extends "res://scripts/camera/isometric_camera.gd"
## Independent framing; shares the game camera controls without changing them.
func reset_view() -> void:
	super.reset_view()
	position = Vector3(0.0, 3.0, 2.0)
