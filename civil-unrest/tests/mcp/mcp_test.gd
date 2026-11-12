extends Node2D
## MCP operational test, deliberately independent of the project's main scene.
const Simulation = preload("res://tests/mcp/mcp_test_simulation.gd")
var simulation := Simulation.new()
var motion_paused: bool = false
var pause_toggles: int = 0
var rendered_frames: int = 0
var fps: float = 0.0
@onready var status: Label = $HUD/Status
@onready var simulation_timer: Timer = $SimulationTimer

func _ready() -> void:
	simulation.reset(_movement_area())
	simulation_timer.timeout.connect(_on_simulation_tick)
	get_viewport().size_changed.connect(_on_viewport_resized)
	print("MCP_TEST_READY agents=20 simulation_hz=30 seed=deterministic")

func _movement_area() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(Vector2(30, 140), Vector2(maxf(120.0, size.x - 60.0), maxf(100.0, size.y - 170.0)))

func _on_viewport_resized() -> void:
	simulation.bounds = _movement_area()
	queue_redraw()

func _on_simulation_tick() -> void:
	if not motion_paused:
		simulation.step(simulation_timer.wait_time)

func _process(_delta: float) -> void:
	rendered_frames += 1
	fps = Engine.get_frames_per_second()
	var state_text := "IN PAUSA" if motion_paused else "IN MOVIMENTO"
	status.text = "Test operativo Godot MCP | 20 agenti\nFPS: %.0f | %s | tick: %d\nSPAZIO: pausa / riprendi" % [fps, state_text, simulation.ticks]
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			motion_paused = not motion_paused
			pause_toggles += 1
			print("MCP_TEST_PAUSE paused=%s ticks=%d" % [motion_paused, simulation.ticks])
			get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(get_viewport_rect(), Color("#101824"))
	if simulation.positions.size() != Simulation.COUNT:
		return
	var area := _movement_area().grow(Simulation.RADIUS + 2.0)
	draw_rect(area, Color("#263549"), false, 2.0)
	for i in range(Simulation.COUNT):
		var color := Color.from_hsv(float(i) / float(Simulation.COUNT), 0.65, 0.95)
		draw_circle(simulation.positions[i], Simulation.RADIUS, color, true, -1.0, true)
		draw_circle(simulation.positions[i], Simulation.RADIUS, Color("#dce8f5"), false, 1.0, true)

func get_test_state() -> Dictionary:
	var points: Array = []
	var all_finite: bool = true
	for point: Vector2 in simulation.positions:
		points.append([point.x, point.y])
		all_finite = all_finite and point.is_finite()
	return {
		"agent_count": simulation.positions.size(),
		"positions": points,
		"motion_paused": motion_paused,
		"pause_toggles": pause_toggles,
		"simulation_ticks": simulation.ticks,
		"rendered_frames": rendered_frames,
		"fps": fps,
		"minimum_distance": simulation.minimum_distance(),
		"all_finite": all_finite
	}
