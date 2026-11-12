extends Node3D
## Composition only: the 2D core, camera and 3D presentation remain separate.
const Session = preload("res://scripts/presentation/crowd_session.gd")
const Renderer = preload("res://scripts/rendering/crowd_renderer_3d.gd")
const CameraRig = preload("res://scripts/camera/isometric_camera.gd")
const Adapter = preload("res://scripts/rendering/crowd_3d_adapter.gd")
@export_range(50, 100, 50) var agent_count: int = 100
@export var random_seed: int = 20261112
@export var max_fps: int = 60
@onready var session: Session = $CrowdSession
@onready var renderer: Renderer = $CrowdRenderer
@onready var camera_rig: CameraRig = $CameraRig
@onready var status: Label = $HUD/Status
var hud_elapsed: float = 0.0
var snapshot: Dictionary = {}
var diagnostics_snapshot: Dictionary = {}

func _ready() -> void:
	# Runtime-only settings; project.godot and other independently launched scenes are untouched.
	Engine.max_fps = max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = Viewport.MSAA_2X
	configure_agents(agent_count)

func configure_agents(count: int) -> void:
	assert(count == 50 or count == 100)
	agent_count = count
	session.configure(count, random_seed)
	renderer.configure(session.simulation.state)
	diagnostics_snapshot = session.simulation.diagnostics()
	_capture_snapshot()

func _process(delta: float) -> void:
	session.advance(delta)
	renderer.present(session.interpolation())
	hud_elapsed += delta
	if hud_elapsed >= 0.25:
		hud_elapsed = 0.0
		diagnostics_snapshot = session.simulation.diagnostics()
		status.text = "%d PERSONE   /   %d FPS\nSimulazione 2D · vista 3D%s" % [agent_count, Engine.get_frames_per_second(), " · PAUSA" if session.paused else ""]

	_capture_snapshot()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1:
			configure_agents(50)
		KEY_2:
			configure_agents(100)
		KEY_SPACE:
			session.paused = not session.paused

func get_slice_state() -> Dictionary:
	# Debugger requests may interrupt simulation work. Never rebuild its grid here.
	# Published dictionaries are replaced, not mutated, after each completed frame.
	return snapshot

func _capture_snapshot() -> void:
	var state := session.simulation.state
	snapshot = {
		"agent_count": agent_count, "seed": random_seed, "paused": session.paused,
		"ticks": session.simulation.ticks, "debt_seconds": session.accumulator,
		"first_position_2d": state.positions[0], "first_previous_2d": state.previous[0],
		"rendering": renderer.get_render_state(),
		"camera": camera_rig.get_camera_state(), "diagnostics": diagnostics_snapshot,
		"viewport": get_viewport().get_visible_rect().size, "max_fps": Engine.max_fps,
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"msaa_3d": get_viewport().msaa_3d, "simulation_tick_ms": session.simulation.simulation_usec / 1000.0
	}
