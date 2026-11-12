extends SceneTree
## Regression: optimized renderer buffers equal the reference composition root * bone * local.
## Usage: godot --headless --path . --script res://tests/presentation/character_renderer_checks.gd
const Renderer = preload("res://scripts/characters/character_renderer.gd")
const Catalog = preload("res://scripts/characters/character_catalog.gd")
const Poses = preload("res://scripts/characters/character_pose_library.gd")
const COUNT: int = 45
const FRAME: float = 1.0 / 60.0
var failures: Array[String] = []
var checks: int = 0

func require(condition: bool, message: String) -> void:
	checks += 1
	if not condition and not failures.has(message):
		failures.append(message)

var started: bool = false

func _process(_delta: float) -> bool:
	# Nodes added in _initialize enter the tree before the first frame.
	if not started:
		started = true
		run()
	return false

func run() -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 70.0
	root.add_child(camera)
	var renderer: Renderer = Renderer.new()
	root.add_child(renderer)
	var types := PackedInt32Array(); var styles := PackedInt32Array()
	for i in range(COUNT):
		types.append(i % 3); styles.append(i % 15)
	renderer.configure(types, styles)
	for level in range(3):
		renderer.forced_lod = level
		check_level(renderer, camera, level, types, styles)
	check_pause(renderer, camera)
	var output := {"checks": checks, "failures": failures, "passed": failures.is_empty()}
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)

func drive(renderer: Renderer, frame: int) -> void:
	for i in range(COUNT):
		# Mixed motion: still, walking, running and turning characters.
		var speed: float = [0.0, 1.2, 3.0, 0.0][i % 4]
		var heading := float(i) * .7 + (float(frame) * .05 if i % 4 == 3 else 0.0)
		var direction := Vector3(-sin(heading), 0, -cos(heading))
		var point: Vector3 = Vector3(float(i % 9) * 2.0, .06, floorf(i / 9.0) * 2.0) + direction * speed * float(frame) * FRAME
		renderer.visual.submit(i, point, direction * speed, heading, FRAME)

func check_level(renderer: Renderer, camera: Camera3D, level: int, types: PackedInt32Array, styles: PackedInt32Array) -> void:
	var pose_counts := PackedInt32Array()
	for frame in range(90):
		drive(renderer, frame)
		renderer.present(FRAME, camera)
		if frame > 0:
			pose_counts.append(renderer.pose_updates)
		if frame % 7 == 0 or frame == 1:
			compare_buffers(renderer, level)
	require(renderer.lod == level, "Forced LOD %d applied" % level)
	# Staggered pose ticks: no frame resamples everyone at once below 60 Hz.
	var limit := ceili(float(COUNT) * Renderer.POSE_HZ[level] / 60.0) + 2
	for value in pose_counts:
		require(value <= limit, "LOD %d pose updates staggered" % level)
	var expected := 0
	var hidden := 0
	for i in range(COUNT):
		var parts := Catalog.parts(types[i], styles[i])
		for part: Dictionary in parts:
			if part.lod >= level:
				if Renderer.is_hidden(part, parts):
					hidden += 1
				else:
					expected += 1
	require(renderer.part_count == expected and renderer.hidden_parts == hidden, "LOD %d part count" % level)
	# Only police details fully enclosed by the opaque vest box (LOD 0) qualify; far LODs are unchanged.
	require(hidden == ([5 * COUNT / 3, 0, 0][level] as int), "Enclosed-part culling count at LOD %d" % level)
	var drawn := 0
	for shape in range(3):
		drawn += renderer.batches[shape].instance_count
		require(renderer.buffers[shape].size() == renderer.batches[shape].instance_count * Renderer.STRIDE, "Buffer size LOD %d" % level)
	require(drawn == renderer.part_count, "Instance count LOD %d" % level)

func compare_buffers(renderer: Renderer, level: int) -> void:
	for i in range(COUNT):
		var heading: float = renderer.written_headings[i]
		require(absf(wrapf(renderer.visual.headings[i] - heading, -PI, PI)) <= Renderer.HEADING_TOLERANCE[level] + .000001, "Heading drift within LOD %d tolerance" % level)
		if level == 0:
			require(is_equal_approx(heading, renderer.visual.headings[i]), "LOD 0 heading refreshed every frame")
		var root_transform := Transform3D(Basis(Vector3.UP, heading).scaled_local(Vector3.ONE * renderer.scales[i]), renderer.visual.positions[i])
		var bones: Array = renderer.current_pose[i]
		for p in range(renderer.part_start[i], renderer.part_start[i + 1]):
			var reference: Transform3D = root_transform * (bones[renderer.part_bone[p]] as Transform3D) * renderer.part_local[p]
			require(read_transform(renderer, p).is_equal_approx(reference), "LOD %d buffer equals reference composition" % level)

func read_transform(renderer: Renderer, p: int) -> Transform3D:
	var b := renderer.buffers[renderer.part_shape[p]]
	var k: int = renderer.part_slot[p] * Renderer.STRIDE
	return Transform3D(Vector3(b[k], b[k + 4], b[k + 8]), Vector3(b[k + 1], b[k + 5], b[k + 9]),
		Vector3(b[k + 2], b[k + 6], b[k + 10]), Vector3(b[k + 3], b[k + 7], b[k + 11]))

func check_pause(renderer: Renderer, camera: Camera3D) -> void:
	renderer.forced_lod = 2
	# Let every character reach one pose tick on the frozen state, then nothing may change.
	for frame in range(8):
		renderer.present(FRAME, camera)
	var before: Array[PackedFloat32Array] = []
	for shape in range(3):
		before.append(renderer.buffers[shape].duplicate())
	var translated := 0
	for frame in range(30):
		renderer.present(FRAME, camera) # No submit: visual state frozen as during a pause.
		translated += renderer.translated
	require(translated == 0, "Paused characters are not re-translated")
	for shape in range(3):
		require(renderer.buffers[shape] == before[shape], "Paused buffers unchanged")
	var p0 := renderer.part_start[0]
	var color_index: int = renderer.part_slot[p0] * Renderer.STRIDE + 12
	require(renderer.buffers[renderer.part_shape[p0]][color_index + 3] == 1.0, "Colors stored in buffer")
