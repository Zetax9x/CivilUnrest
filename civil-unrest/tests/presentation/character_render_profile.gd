extends SceneTree
## Windowed phase profile of character rendering techniques on identical data.
## Self-contained: rebuilds the pre-optimization (legacy) pipeline from the catalog,
## so results stay reproducible regardless of the current renderer implementation.
## Usage: godot --path . --resolution 1152x648 --max-fps 60 --disable-vsync
##        --script res://tests/presentation/character_render_profile.gd -- --count=800 --tag=before
const Catalog = preload("res://scripts/characters/character_catalog.gd")
const Poses = preload("res://scripts/characters/character_pose_library.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Recorder = preload("res://scripts/benchmarks/benchmark_recorder.gd")
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
const WARMUP_SECONDS: float = 4.0
const PHASE_FRAMES: int = 240
const GPU_SECONDS: float = 8.0
const LEVEL: int = 2
var scene: Node3D
var count: int = 800
var tag: String = "profile"
var visual := Visual.new()
var poses := Poses.new()
var bindings: Array = []
var bone_cache: Array = []
var clocks := PackedFloat32Array()
var scales := PackedFloat32Array()
var batches: Array[MultiMesh] = []
var composed: Array = [[], [], []]
var buffers: Array[PackedFloat32Array] = []
var cached_origins: Array[PackedVector3Array] = []
var slot_agent: Array[PackedInt32Array] = []
var recorder := Recorder.new()
var elapsed: float = 0.0
var stage: String = "warmup"
var frames_done: int = 0
var gpu_samples := PackedFloat64Array()
var cpu_samples := PackedFloat64Array()
var hidden_gpu_samples := PackedFloat64Array()

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--count="):
			count = int(argument.get_slice("=", 1))
		elif argument.begins_with("--tag="):
			tag = argument.get_slice("=", 1).validate_filename()
	scene = load("res://scenes/benchmarks/UrbanCrowd3D.tscn").instantiate()
	root.add_child(scene)
	scene.configure_case.call_deferred(count, "chokepoint")

func _process(delta: float) -> bool:
	elapsed += delta
	match stage:
		"warmup":
			if elapsed >= WARMUP_SECONDS:
				_begin_gpu()
		"gpu":
			gpu_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
			cpu_samples.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
			if elapsed >= GPU_SECONDS:
				scene.characters.visible = false
				stage = "gpu_hidden"; elapsed = 0.0
		"gpu_hidden":
			hidden_gpu_samples.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
			if elapsed >= GPU_SECONDS * .5:
				_begin_phases()
		"phases":
			_profile_frame(delta)
			frames_done += 1
			if frames_done >= PHASE_FRAMES:
				_finish()
				return true
	return false

func _begin_gpu() -> void:
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	stage = "gpu"; elapsed = 0.0

func _begin_phases() -> void:
	# The scene keeps simulating; its own character renderer is replaced by the profiled copy.
	scene.set_process(false)
	scene.characters.visible = false
	_build_legacy(scene.characters.visual.count)
	recorder.begin()
	stage = "phases"

func _build_legacy(size: int) -> void:
	visual.configure(size)
	clocks.resize(size); scales.resize(size); clocks.fill(1.0)
	var sizes := PackedInt32Array([0, 0, 0])
	for i in range(size):
		var style: int = i % 15
		scales[i] = .96 + float(style % 5) * .02
		var bones: Array[Transform3D] = []
		bones.resize(Poses.BONES); bones.fill(Transform3D.IDENTITY)
		bone_cache.append(bones)
		var selected: Array[Dictionary] = []
		for part: Dictionary in Catalog.parts(scene.session.simulation.state.groups[i], style):
			if part.lod < LEVEL:
				continue
			var binding: Dictionary = part.duplicate()
			binding.slot = sizes[part.shape]
			if part.shape == 2:
				binding.local = part.local * Transform3D(Basis.IDENTITY.scaled_local(Vector3(1, .5, 1)), Vector3.ZERO)
			sizes[part.shape] += 1
			selected.append(binding)
		bindings.append(selected)
	var meshes := [BoxMesh.new(), SphereMesh.new(), CapsuleMesh.new()]
	for shape in range(3):
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = meshes[shape]
		multi.instance_count = sizes[shape]
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		scene.add_child(instance)
		batches.append(multi)
		composed[shape].resize(sizes[shape])
		var buffer := PackedFloat32Array(); buffer.resize(sizes[shape] * 16)
		buffers.append(buffer)
		var origins := PackedVector3Array(); origins.resize(sizes[shape])
		cached_origins.append(origins)
		var owners := PackedInt32Array(); owners.resize(sizes[shape])
		slot_agent.append(owners)
	for i in range(size):
		for binding: Dictionary in bindings[i]:
			slot_agent[binding.shape][binding.slot] = i
			batches[binding.shape].set_instance_color(binding.slot, binding.color.srgb_to_linear())
	for shape in range(3):
		buffers[shape] = batches[shape].buffer

func _profile_frame(delta: float) -> void:
	scene.session.advance(delta)
	var t := Time.get_ticks_usec()
	Bridge.submit(visual, scene.session.simulation.state, scene.session.interpolation(), delta, Simulation.FIXED_DELTA)
	t = _mark("adapter", t)
	_pose_legacy(delta)
	t = _mark("pose_legacy_10hz_synchronized", t)
	_alloc_probe()
	t = _mark("hz_array_literal_per_agent", t)
	_compose_legacy()
	t = _mark("compose_root_bone_local", t)
	_upload_per_instance()
	t = _mark("upload_set_instance_transform", t)
	_pack_buffers()
	t = _mark("pack_12_floats_per_part", t)
	_send_buffers()
	t = _mark("multimesh_set_buffer", t)
	_translate_only()
	t = _mark("pack_origin_only_per_part", t)
	_pose_interpolated_all()
	t = _mark("pose_interpolated_all_agents", t)
	_pose_nearest_all()
	t = _mark("pose_nearest_lookup_all_agents", t)
	recorder.frame(0)

func _mark(name: String, started: int) -> int:
	var now := Time.get_ticks_usec()
	recorder.detail(name, now - started)
	return now

func _pose_legacy(delta: float) -> void:
	for i in range(visual.count):
		clocks[i] += delta
		var hz: float = [60.0, 30.0, 10.0][LEVEL]
		if clocks[i] + .00001 >= 1.0 / hz:
			clocks[i] = maxf(0.0, clocks[i] - floor((clocks[i] + .00001) * hz) / hz)
			_sample_interpolated(i)

func _sample_interpolated(i: int) -> void:
	for bone in range(Poses.BONES):
		var current := poses.sample(visual.states[i], visual.phases[i], bone)
		if visual.blends[i] < 1.0:
			current = poses.sample(visual.previous_states[i], visual.previous_phases[i], bone).interpolate_with(current, visual.blends[i])
		bone_cache[i][bone] = current

func _alloc_probe() -> void:
	var total: float = 0.0
	for i in range(visual.count):
		var hz: float = [60.0, 30.0, 10.0][LEVEL]
		total += hz
	assert(total > 0.0)

func _compose_legacy() -> void:
	for i in range(visual.count):
		var root_transform := Transform3D(Basis(Vector3.UP, visual.headings[i]).scaled_local(Vector3.ONE * scales[i]), visual.positions[i])
		for binding: Dictionary in bindings[i]:
			var bone: Transform3D = bone_cache[i][binding.bone]
			composed[binding.shape][binding.slot] = root_transform * bone * binding.local

func _upload_per_instance() -> void:
	for shape in range(3):
		var multi := batches[shape]
		var transforms: Array = composed[shape]
		for slot in range(transforms.size()):
			multi.set_instance_transform(slot, transforms[slot])

func _pack_buffers() -> void:
	for shape in range(3):
		var buffer := buffers[shape]
		var transforms: Array = composed[shape]
		var origins := cached_origins[shape]
		for slot in range(transforms.size()):
			var x: Transform3D = transforms[slot]
			var k := slot * 16
			buffer[k] = x.basis.x.x; buffer[k + 1] = x.basis.y.x; buffer[k + 2] = x.basis.z.x; buffer[k + 3] = x.origin.x
			buffer[k + 4] = x.basis.x.y; buffer[k + 5] = x.basis.y.y; buffer[k + 6] = x.basis.z.y; buffer[k + 7] = x.origin.y
			buffer[k + 8] = x.basis.x.z; buffer[k + 9] = x.basis.y.z; buffer[k + 10] = x.basis.z.z; buffer[k + 11] = x.origin.z
			origins[slot] = x.origin - visual.positions[slot_agent[shape][slot]]
		buffers[shape] = buffer

func _send_buffers() -> void:
	for shape in range(3):
		RenderingServer.multimesh_set_buffer(batches[shape].get_rid(), buffers[shape])

func _translate_only() -> void:
	for shape in range(3):
		var buffer := buffers[shape]
		var origins := cached_origins[shape]
		var owners := slot_agent[shape]
		for slot in range(origins.size()):
			var o: Vector3 = origins[slot] + visual.positions[owners[slot]]
			var k := slot * 16
			buffer[k + 3] = o.x; buffer[k + 7] = o.y; buffer[k + 11] = o.z
		buffers[shape] = buffer

func _pose_interpolated_all() -> void:
	for i in range(visual.count):
		_sample_interpolated(i)

func _pose_nearest_all() -> void:
	for i in range(visual.count):
		var state: int = visual.states[i]
		var frame := int(visual.phases[i] * (Poses.STEPS - 1) + .5) if state == Poses.State.STOP else int(fposmod(visual.phases[i], 1.0) * Poses.STEPS + .5) % Poses.STEPS
		bone_cache[i] = poses.bank[state][frame]

func _finish() -> void:
	var row := recorder.finish()
	var gpu := recorder.stats(gpu_samples)
	var cpu := recorder.stats(cpu_samples)
	var output := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"gpu_name": RenderingServer.get_video_adapter_name(), "count": count, "scenario": "chokepoint", "level": LEVEL,
		"parts": [composed[0].size(), composed[1].size(), composed[2].size()], "phase_frames": PHASE_FRAMES,
		"phase_ms": row.component_ms, "viewport_render_gpu_ms": gpu, "viewport_render_cpu_ms": cpu,
		"viewport_render_gpu_characters_hidden_ms": recorder.stats(hidden_gpu_samples),
		"build": "debug standalone" if OS.is_debug_build() else "exported release"}
	var file := FileAccess.open("res://docs/urban_crowd_3d/render_profile_%s.json" % tag, FileAccess.WRITE)
	assert(file != null, "Cannot save render profile")
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	for key: String in row.component_ms:
		print("PROFILE %s mean=%.3f p95=%.3f" % [key, row.component_ms[key].mean, row.component_ms[key].p95])
	print("PROFILE gpu_hidden_ms mean=%.3f" % recorder.stats(hidden_gpu_samples).get("mean", -1.0))
	print("PROFILE gpu_ms mean=%.3f p95=%.3f cpu_ms mean=%.3f" % [gpu.get("mean", -1.0), gpu.get("p95", -1.0), cpu.get("mean", -1.0)])
