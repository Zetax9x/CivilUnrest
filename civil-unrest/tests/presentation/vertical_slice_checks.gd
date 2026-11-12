extends SceneTree
const Adapter = preload("res://scripts/rendering/crowd_3d_adapter.gd")
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _require(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/Main.tscn")
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var urban = main.get_node("WorldHost/UrbanSquare")
	urban.set_process(false)
	urban.camera_rig.set_process(false)
	var samples: Array[Vector2] = [Vector2.ZERO, Vector2(800, 450), Vector2(1600, 900), Vector2(224, 613)]
	for point in samples:
		var world := Adapter.to_world(point)
		_require(Adapter.to_simulation(world).distance_to(point) < 0.0001, "Coordinate round trip")
		_require(world.is_finite(), "Finite world point")
	_require(is_equal_approx(Adapter.to_world(Vector2(810, 450)).x, 0.5), "Physical diameter preserved")
	var populations: Array[Dictionary] = []
	for count in [50, 100]:
		urban.configure_agents(count)
		urban.session.paused = false
		var reference := Simulation.new()
		reference.reset(count, "dispersed", 20261112)
		var deterministic := true
		for tick in range(120):
			urban.session.advance(Simulation.FIXED_DELTA)
			reference.step()
			deterministic = deterministic and urban.session.simulation.state.positions == reference.state.positions
		_require(deterministic, "Existing core determinism at %d" % count)
		var positions: PackedVector2Array = urban.session.simulation.state.positions.duplicate()
		urban.renderer.present(0.5)
		urban.renderer.present(1.0)
		_require(positions == urban.session.simulation.state.positions, "Read-only renderer")
		var expected := Adapter.to_world(positions[0]) + Vector3(0, 0.95, 0)
		_require(urban.renderer.bodies.get_instance_transform(0).origin.distance_to(expected) < 0.0001, "Rendered coordinate mapping")
		_require(urban.renderer.bodies.instance_count == count, "MultiMesh count")
		var diagnostics: Dictionary = reference.diagnostics()
		_require(diagnostics.invalid_positions == 0 and diagnostics.overlap_pairs == 0, "Core separation and bounds")
		populations.append({"count": count, "ticks": reference.ticks, "deterministic": deterministic, "diagnostics": diagnostics})
	# Four-step cap must preserve time debt rather than discard fixed ticks.
	urban.configure_agents(50)
	urban.session.advance(Simulation.FIXED_DELTA * 10.5)
	_require(urban.session.simulation.ticks == 4 and urban.session.accumulator > Simulation.FIXED_DELTA * 6, "Catch-up debt preserved")
	urban.session.advance(0.0)
	urban.session.advance(0.0)
	_require(urban.session.simulation.ticks == 10, "Debt eventually processed")
	var saved: PackedVector2Array = urban.session.simulation.state.positions.duplicate()
	urban.session.paused = true
	urban.session.advance(1.0)
	_require(saved == urban.session.simulation.state.positions, "Paused session")
	# Regression: remote inspection must be pure, never rebuild the shared grid.
	var grid_heads: PackedInt32Array = urban.session.simulation.grid.heads.duplicate()
	var grid_links: PackedInt32Array = urban.session.simulation.grid.links.duplicate()
	var published: Dictionary = urban.get_slice_state()
	for read in range(20):
		urban.get_slice_state()
	_require(grid_heads == urban.session.simulation.grid.heads and grid_links == urban.session.simulation.grid.links, "Inspection leaves spatial grid unchanged")
	_require(published == urban.get_slice_state(), "Inspection returns completed snapshot")
	var camera = urban.camera_rig
	camera.reset_view()
	_require(camera.camera.projection == Camera3D.PROJECTION_ORTHOGONAL and camera.camera.rotation_degrees.x == -45.0, "Orthographic 45-degree camera")
	for turn in range(4):
		camera.rotate_step(1)
	_require(is_equal_approx(camera.rotation_degrees.y, camera.initial_yaw), "Four quarter turns")
	camera.zoom_by(0.0001)
	_require(camera.camera.size == camera.min_zoom, "Minimum zoom")
	camera.zoom_by(100000.0)
	_require(camera.camera.size == camera.max_zoom, "Maximum zoom")
	camera.pan(Vector2(100000, 100000))
	_require(camera.position.x >= camera.pan_bounds.position.x and camera.position.x <= camera.pan_bounds.end.x and camera.position.z >= camera.pan_bounds.position.y and camera.position.z <= camera.pan_bounds.end.y, "Pan bounds")
	for footprint: Rect2 in urban.get_node("EnvironmentGeometry").solid_footprints:
		_require(not footprint.intersects(Rect2(-40.4, -22.9, 80.8, 45.8)), "Static solids outside crowd domain")
	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "populations": populations}
	print("VERTICAL_SLICE_CHECKS " + JSON.stringify(result))
	var file := FileAccess.open("res://docs/visual_slice/checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
