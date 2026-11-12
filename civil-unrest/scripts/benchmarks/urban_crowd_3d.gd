extends Node3D
## Composition and measurement only; core and animated renderer own their logic.
const Session = preload("res://scripts/presentation/crowd_session.gd")
const Characters = preload("res://scripts/characters/character_renderer.gd")
const Recorder = preload("res://scripts/benchmarks/benchmark_recorder.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Ground = preload("res://scripts/rendering/crowd_3d_adapter.gd")
@export var agent_count: int = 100
@export_enum("dispersed", "chokepoint") var scenario_kind: String = "chokepoint"
@export var random_seed: int = 20261112
@onready var session: Session = $CrowdSession
@onready var characters: Characters = $Characters
@onready var camera_rig: Node3D = $CameraRig
@onready var status: Label = $HUD/Status
var recorder := Recorder.new()
var measuring: bool = false
var suite_running: bool = false
var suite_finished: bool = false
var paused_before_capture: bool = false
var largest_debt: float = 0.0
var diagnostics_snapshot: Dictionary = {}
var peaks: Dictionary = {}
var results: Array[Dictionary] = []
var skipped: Array[String] = []
var hud_elapsed: float = 0.0
var snapshot: Dictionary = {}
var warmup_seconds: float = 4.0
var sample_seconds: float = 8.0
var result_tag: String = "urban_3d"
var quit_on_complete: bool = false
var selected_counts: Array[int] = [20,100,300,600,800]
var selected_scenarios: Array[String] = ["dispersed","chokepoint"]
var camera_size_override: float = 0.0 # Optional fixed ortho size to benchmark LOD 0/1.

func _ready() -> void:
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	# GPU timer queries for the whole viewport (environment + characters); same in every case.
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	session.tick_completed.connect(_on_tick)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--count="):
			selected_counts.assign([int(argument.get_slice("=",1))])
		elif argument.begins_with("--scenario="):
			selected_scenarios.assign([argument.get_slice("=",1)])
		elif argument.begins_with("--tag="):
			result_tag = argument.get_slice("=",1).validate_filename()
		elif argument.begins_with("--camera-size="):
			camera_size_override = float(argument.get_slice("=",1))
		elif argument == "--quit-on-complete":
			quit_on_complete = true
	configure_case(agent_count,scenario_kind)
	if "--suite" in OS.get_cmdline_user_args():
		run_suite.call_deferred()

func configure_case(count: int, kind: String) -> void:
	assert(count in [20,100,300,600,800])
	assert(kind in ["dispersed","chokepoint"])
	agent_count = count; scenario_kind = kind
	session.paused = false
	session.configure(count,random_seed,kind)
	var types := session.simulation.state.groups.duplicate()
	var styles := PackedInt32Array()
	styles.resize(count)
	for i in range(count):
		styles[i] = i % 15
	characters.configure(types,styles)
	$Barriers.configure(session.simulation.scenario.obstacles)
	diagnostics_snapshot = session.simulation.diagnostics()
	peaks = {"blocked_agents":0,"overlap_pairs":0,"invalid_positions":0,"max_penetration":0.0}
	largest_debt = 0.0
	_publish()

func _on_tick(sim_usec: int, grid_usec: int, move_usec: int, separate_usec: int) -> void:
	if measuring:
		recorder.tick(sim_usec,grid_usec,move_usec,separate_usec)
	if session.simulation.ticks % 30 == 0:
		diagnostics_snapshot = session.simulation.diagnostics()
		if measuring:
			for key: String in peaks:
				peaks[key] = maxf(float(peaks[key]),float(diagnostics_snapshot[key]))

func _process(delta: float) -> void:
	session.advance(delta)
	largest_debt = maxf(largest_debt,session.accumulator)
	var started := Time.get_ticks_usec()
	if not session.paused:
		Bridge.submit(characters.visual,session.simulation.state,session.interpolation(),maxf(delta,.000001),Session.Simulation.FIXED_DELTA)
	var adapter_usec := Time.get_ticks_usec() - started
	characters.present(delta,camera_rig.camera)
	var renderer_usec := Time.get_ticks_usec() - started
	if measuring:
		recorder.frame(renderer_usec)
		recorder.detail("adapter",adapter_usec)
		recorder.detail("pose",characters.pose_usec)
		recorder.detail("part_submission",characters.submission_usec - characters.pose_usec)
		# Optional counters: absent in the pre-optimization renderer used for A/B runs.
		var counters := {"prepare_usec":"transform_prepare","upload_usec":"multimesh_upload","full_updates":"full_updates_count","translated":"translated_count"}
		for key: String in counters:
			if key in characters:
				var value: int = characters.get(key)
				# *_count series store plain counts (recorded x1000 so the ms conversion yields the count).
				recorder.detail(counters[key],value if key.ends_with("_usec") else value*1000)
		recorder.detail("gpu_viewport",int(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())*1000.0))
	hud_elapsed += delta
	if hud_elapsed >= .5:
		hud_elapsed = 0.0
		status.text = "%d PERSONE / %s / %d FPS / LOD %d\nCPU sim %.2f ms  |  1–5: quantità  C: scenario  SPAZIO: pausa  B: benchmark\nWASD / rotella / Q E / HOME" % [agent_count,scenario_kind,Engine.get_frames_per_second(),characters.lod,session.simulation.simulation_usec/1000.0]
		_publish()

func _publish() -> void:
	# Read-only MCP getter returns a completed snapshot; no grid rebuilding.
	snapshot = {"count":agent_count,"scenario":scenario_kind,"ticks":session.simulation.ticks,
		"debt_seconds":session.accumulator,"diagnostics":diagnostics_snapshot,"render":characters.get_render_state(),
		"camera":camera_rig.get_camera_state(),"paused":session.paused,
		"suite_running":suite_running,"suite_finished":suite_finished,"completed":results.size()}

func get_benchmark_state() -> Dictionary:
	return snapshot

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or suite_running:
		return
	match event.physical_keycode:
		KEY_1: configure_case(20,scenario_kind)
		KEY_2: configure_case(100,scenario_kind)
		KEY_3: configure_case(300,scenario_kind)
		KEY_4: configure_case(600,scenario_kind)
		KEY_5: configure_case(800,scenario_kind)
		KEY_C: configure_case(agent_count,"dispersed" if scenario_kind == "chokepoint" else "chokepoint")
		KEY_SPACE: session.paused = not session.paused
		KEY_B: run_suite()

func run_suite() -> void:
	if suite_running:
		return
	suite_running = true; suite_finished = false
	results.clear(); skipped.clear()
	camera_rig.reset_view()
	if camera_size_override > 0.0:
		camera_rig.camera.size = camera_size_override
	for count in selected_counts:
		if count == 800:
			var prior := results.filter(func(row: Dictionary) -> bool: return row.agent_count == 600)
			if not prior.is_empty() and prior.any(func(row: Dictionary) -> bool: return row.simulation_hz_measured < 29.0 or row.largest_debt_seconds > .5 or row.frame_ms.p95 > 100.0):
				skipped.append("800: 600-agent cases exceeded 100 ms p95, 0.5 s debt, or fell below 29 simulation Hz")
				continue
		for kind in selected_scenarios:
			configure_case(count,kind)
			await _wall_wait(warmup_seconds)
			var first_tick := session.simulation.ticks
			largest_debt = 0.0
			peaks = {"blocked_agents":0,"overlap_pairs":0,"invalid_positions":0,"max_penetration":0.0}
			recorder.begin(); measuring = true
			await _wall_wait(sample_seconds)
			measuring = false
			var row := recorder.finish()
			row.agent_count = count; row.scenario = kind; row.seed = random_seed
			row.warmup_seconds = warmup_seconds
			row.start_tick = first_tick; row.end_tick = session.simulation.ticks
			row.simulation_hz_measured = float(row.end_tick-first_tick)/row.duration_seconds
			row.largest_debt_seconds = largest_debt
			row.diagnostics = session.simulation.diagnostics()
			row.sampled_peaks = peaks.duplicate()
			row.lod = characters.lod; row.parts = characters.part_count
			row.video_memory_mib = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0
			row.nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			row.draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			row.transitions = Array(characters.visual.transitions)
			results.append(row)
			_save_results()
			print("URBAN_RESULT count=%d scenario=%s fps=%.3f p95=%.3f sim_ms=%.3f render_ms=%.3f tick_hz=%.3f overlap=%d blocked=%d" % [count,kind,row.fps,row.frame_ms.p95,row.simulation_tick_ms.mean,row.render_submission_ms.mean,row.simulation_hz_measured,row.diagnostics.overlap_pairs,row.diagnostics.blocked_agents])
	suite_running = false; suite_finished = true
	_save_results(); _publish()
	print("URBAN_SUITE_DONE " + result_tag)
	if quit_on_complete:
		get_tree().quit()

func _wall_wait(seconds: float) -> void:
	var deadline := Time.get_ticks_usec() + int(seconds*1000000.0)
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame

func _save_results() -> void:
	var directory := "res://docs/urban_crowd_3d"
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory + "/" + result_tag + ".json",FileAccess.WRITE)
	assert(file != null,"Cannot save urban benchmark")
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"build":"debug standalone" if OS.is_debug_build() else "exported release",
		"processor":OS.get_processor_name(),"os":OS.get_name(),"os_version":OS.get_version(),"gpu":RenderingServer.get_video_adapter_name(),
		"viewport":get_viewport().get_visible_rect().size,"msaa":get_viewport().msaa_3d,"max_fps":Engine.max_fps,
		"vsync":DisplayServer.window_get_vsync_mode(),"camera":camera_rig.get_camera_state(),
		"fixed_hz":30,"skipped":skipped,"completed":suite_finished,"results":results},"\t"))
	file.close()
