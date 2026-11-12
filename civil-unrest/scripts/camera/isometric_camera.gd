extends Node3D
## Independent camera: input never touches simulation data.
@export var pan_speed: float = 24.0
@export var pan_bounds := Rect2(-28, -18, 56, 36)
@export var min_zoom: float = 24.0
@export var max_zoom: float = 100.0
@export var initial_zoom: float = 68.0
@export var initial_yaw: float = 45.0
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	reset_view()

func reset_view() -> void:
	position = Vector3(-3, 0, -9)
	rotation_degrees = Vector3(0, initial_yaw, 0)
	camera.position = Vector3(0, 70, 70)
	camera.rotation_degrees = Vector3(-45, 0, 0)
	camera.set_orthogonal(clampf(initial_zoom, min_zoom, max_zoom), 0.1, 260.0)
	camera.make_current()

func _process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if input.length_squared() > 0.0:
		pan(input.normalized() * pan_speed * delta * camera.size / initial_zoom)

func pan(amount: Vector2) -> void:
	var world_delta := global_basis * Vector3(amount.x, 0, amount.y)
	var next := Vector2(position.x + world_delta.x, position.z + world_delta.z)
	next = next.clamp(pan_bounds.position, pan_bounds.end)
	position.x = next.x
	position.z = next.y

func zoom_by(factor: float) -> void:
	camera.size = clampf(camera.size * factor, min_zoom, max_zoom)

func rotate_step(direction: int) -> void:
	rotation_degrees.y = wrapf(rotation_degrees.y + direction * 90.0, 0.0, 360.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(0.88)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 0.88)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q:
				rotate_step(-1)
			KEY_E:
				rotate_step(1)
			KEY_HOME:
				reset_view()

func get_camera_state() -> Dictionary:
	return {"position": position, "yaw_degrees": rotation_degrees.y, "pitch_degrees": camera.rotation_degrees.x, "size": camera.size, "projection": camera.projection, "bounds": pan_bounds}
