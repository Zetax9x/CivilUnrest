extends Node2D
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
const Recorder = preload("res://scripts/benchmarks/benchmark_recorder.gd")
@export var agent_count: int = 1000
@export_enum("dispersed", "chokepoint") var scenario_kind: String = "chokepoint"
@export var random_seed: int = 20261112
@export var use_multimesh: bool = false
@export var warmup_seconds: float = 4.0
@export var sample_seconds: float = 8.0
@export var result_tag: String = "optimization_manual"
var suite_counts: Array[int] = [100, 300, 500, 600, 800, 1000]
var suite_scenarios: Array[String] = ["dispersed", "chokepoint"]
var quit_on_complete: bool = false
var simulation := Simulation.new()
var recorder := Recorder.new()
var accumulator: float = 0.0
var last_usec: int = 0
var paused: bool = false
var measuring: bool = false
var suite_running: bool = false
var suite_finished: bool = false
var results: Array[Dictionary] = []
var last_result: Dictionary = {}
var ui_elapsed: float = 0.0
var largest_debt: float = 0.0
var camera_offset := Vector2.ZERO
var camera_zoom: float = 1.0
@onready var renderer: Node2D = $CrowdRenderer
@onready var camera: Camera2D = $Camera
@onready var status: Label = $HUD/Status

func _ready() -> void:
	_configure(agent_count, scenario_kind)
	get_viewport().size_changed.connect(_fit_camera)
	last_usec = Time.get_ticks_usec()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--duration="):
			sample_seconds = maxf(1.0, float(argument.get_slice("=", 1)))
		elif argument.begins_with("--warmup="):
			warmup_seconds = maxf(1.0, float(argument.get_slice("=", 1)))
		elif argument.begins_with("--tag="):
			result_tag = argument.get_slice("=", 1)
		elif argument.begins_with("--count="):
			var selected_count := int(argument.get_slice("=", 1))
			if selected_count not in [100, 300, 500, 600, 800, 1000]:
				push_error("Supported counts: 100, 300, 500, 600, 800, 1000")
				get_tree().quit(2)
				return
			suite_counts.assign([selected_count])
		elif argument.begins_with("--scenario="):
			var selected_scenario := argument.get_slice("=", 1)
			if selected_scenario not in ["dispersed", "chokepoint"]:
				push_error("Supported scenarios: dispersed, chokepoint")
				get_tree().quit(2)
				return
			suite_scenarios.assign([selected_scenario])
		elif argument == "--quit-on-complete":
			quit_on_complete = true
		elif argument == "--multimesh":
			use_multimesh = true
			renderer.configure(simulation.state, simulation.scenario, true)
	if "--suite" in OS.get_cmdline_user_args():
		run_suite.call_deferred()
	print("CROWD_READY count=%d scenario=%s renderer=%s" % [agent_count, scenario_kind, "multimesh" if use_multimesh else "draw"])

func _configure(count: int, kind: String) -> void:
	agent_count = count
	scenario_kind = kind
	simulation.reset(count, kind, random_seed)
	renderer.configure(simulation.state, simulation.scenario, use_multimesh)
	accumulator = 0.0
	largest_debt = 0.0
	_fit_camera()

func _fit_camera() -> void:
	var size := get_viewport_rect().size
	var fit := minf(size.x / 1640.0, (size.y - 120.0) / 940.0)
	camera.zoom = Vector2.ONE * fit * camera_zoom
	camera.position = Vector2(800, 450) + camera_offset - Vector2(0, 55.0 / (fit * camera_zoom))

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var elapsed := float(now - last_usec) / 1000000.0
	last_usec = now
	if not paused:
		accumulator += elapsed
		var steps: int = 0
		while accumulator >= Simulation.FIXED_DELTA and steps < 4:
			simulation.step()
			if measuring:
				recorder.tick(simulation.simulation_usec, simulation.grid_usec, simulation.movement_usec, simulation.separation_usec)
				for component: String in ["rebuild", "pairs", "avoidance", "positions"]:
					var usec: int = simulation.get(component + "_usec") if component in ["rebuild", "pairs"] else simulation.movement.get(component + "_usec")
					recorder.detail(component, usec)
			accumulator -= Simulation.FIXED_DELTA
			steps += 1
		largest_debt = maxf(largest_debt, accumulator)
	renderer.present(accumulator / Simulation.FIXED_DELTA)
	if measuring:
		recorder.frame(renderer.submission_usec)
	ui_elapsed += delta
	if ui_elapsed > 0.2:
		ui_elapsed = 0.0
		status.text = "CivilUnrest | %d agenti | %s | FPS %.0f | sim %.2f ms | griglia %.2f ms\n1/2/3/4: 100/300/500/1000 | C: scenario | SPAZIO: pausa | B: benchmark completo\nFrecce: camera | +/-: zoom | suite: %s | tick %d | transiti %d" % [agent_count, scenario_kind, Engine.get_frames_per_second(), simulation.simulation_usec / 1000.0, simulation.grid_usec / 1000.0, "in corso" if suite_running else ("completata" if suite_finished else "inattiva"), simulation.ticks, simulation.state.crossings]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_B and not suite_running:
		run_suite()
		return
	if suite_running:
		return
	match event.keycode:
		KEY_1: _configure(100, scenario_kind)
		KEY_2: _configure(300, scenario_kind)
		KEY_3: _configure(500, scenario_kind)
		KEY_4: _configure(1000, scenario_kind)
		KEY_C: _configure(agent_count, "dispersed" if scenario_kind == "chokepoint" else "chokepoint")
		KEY_SPACE: paused = not paused
		KEY_LEFT: camera_offset.x -= 80.0
		KEY_RIGHT: camera_offset.x += 80.0
		KEY_UP: camera_offset.y -= 80.0
		KEY_DOWN: camera_offset.y += 80.0
		KEY_EQUAL, KEY_KP_ADD: camera_zoom = minf(2.5, camera_zoom * 1.15)
		KEY_MINUS, KEY_KP_SUBTRACT: camera_zoom = maxf(0.5, camera_zoom / 1.15)
	_fit_camera()

func run_suite() -> void:
	if suite_running:
		return
	suite_running = true
	suite_finished = false
	paused = false
	camera_zoom = 1.0
	camera_offset = Vector2.ZERO
	results.clear()
	for kind: String in suite_scenarios:
		for count: int in suite_counts:
			_configure(count, kind)
			await _wall_wait(warmup_seconds)
			var start_ticks := simulation.ticks
			largest_debt = 0.0
			recorder.begin()
			measuring = true
			await _wall_wait(sample_seconds)
			measuring = false
			var result := recorder.finish()
			result["agent_count"] = count
			result["scenario"] = kind
			result["seed"] = random_seed
			result["warmup_seconds"] = warmup_seconds
			result["simulation_ticks_measured"] = simulation.ticks - start_ticks
			result["simulation_hz_measured"] = float(simulation.ticks - start_ticks) / float(result["duration_seconds"])
			result["largest_debt_seconds"] = largest_debt
			result["diagnostics"] = simulation.diagnostics()
			results.append(result)
			last_result = result
			print("CROWD_RESULT count=%d scenario=%s fps=%.2f sim_ms=%.3f p95_frame=%.3f" % [count, kind, result["fps"], result["simulation_tick_ms"]["mean"], result["frame_ms"]["p95"]])
	var output := {
		"engine": Engine.get_version_info()["string"],
		"build": "debug standalone" if OS.is_debug_build() else "exported release",
		"max_fps": Engine.max_fps,
		"renderer": "multimesh" if use_multimesh else "draw_texture_rect",
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"viewport": [get_viewport_rect().size.x, get_viewport_rect().size.y],
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"fixed_hz": 30,
		"timestamp_utc": Time.get_datetime_string_from_system(true),
		"processor": OS.get_processor_name(),
		"os": OS.get_name(),
		"os_version": OS.get_version(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"memory_definition": "Godot static allocations, not total process working set",
		"results": results
	}
	var directory := "res://docs/benchmark_results"
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory + "/" + result_tag + ".json"
	if FileAccess.file_exists(path):
		path = directory + "/" + result_tag + "_" + str(Time.get_ticks_usec()) + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write benchmark results: " + path)
	else:
		file.store_string(JSON.stringify(output, "\t"))
		file.close()
		print("CROWD_SUITE_DONE " + path)
	suite_running = false
	suite_finished = true
	if quit_on_complete:
		get_tree().quit()

func get_benchmark_state() -> Dictionary:
	return {"suite_running": suite_running, "suite_finished": suite_finished, "completed_cases": results.size(), "count": agent_count, "scenario": scenario_kind, "paused": paused, "simulation_ms": simulation.simulation_usec / 1000.0, "grid_ms": simulation.grid_usec / 1000.0, "movement_ms": simulation.movement_usec / 1000.0, "separation_ms": simulation.separation_usec / 1000.0, "debt_seconds": accumulator, "diagnostics": simulation.diagnostics()}

func _wall_wait(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds * 1000000.0)
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame
