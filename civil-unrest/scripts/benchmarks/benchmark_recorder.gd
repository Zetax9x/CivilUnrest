extends RefCounted
## Wall-clock frame intervals include pacing; CPU spans measure only simulation code.
var frames := PackedFloat64Array()
var simulation := PackedFloat64Array()
var grid := PackedFloat64Array()
var movement := PackedFloat64Array()
var separation := PackedFloat64Array()
var rendering := PackedFloat64Array()
var memory := PackedFloat64Array()
var components: Dictionary = {}
var started_usec: int = 0
var previous_usec: int = 0

func begin() -> void:
	components.clear()
	frames.clear()
	simulation.clear()
	grid.clear()
	movement.clear()
	separation.clear()
	rendering.clear()
	memory.clear()
	started_usec = Time.get_ticks_usec()
	previous_usec = started_usec

func frame(render_usec: int) -> void:
	var now := Time.get_ticks_usec()
	frames.append(float(now - previous_usec) / 1000.0)
	previous_usec = now
	rendering.append(float(render_usec) / 1000.0)
	if frames.size() % 30 == 0:
		memory.append(float(OS.get_static_memory_usage()) / 1048576.0)

func tick(sim_usec: int, grid_usec: int, move_usec: int, separation_usec: int) -> void:
	simulation.append(float(sim_usec) / 1000.0)
	grid.append(float(grid_usec) / 1000.0)
	movement.append(float(move_usec) / 1000.0)
	separation.append(float(separation_usec) / 1000.0)

func detail(name: String, usec: int) -> void:
	if not components.has(name):
		components[name] = PackedFloat64Array()
	components[name].append(float(usec) / 1000.0)

func stats(values: PackedFloat64Array) -> Dictionary:
	if values.is_empty():
		return {}
	var sorted := values.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value in values:
		total += value
	return {"mean": total / values.size(), "median": sorted[floori(float(sorted.size() - 1) * 0.5)], "p95": sorted[ceili(float(sorted.size() - 1) * 0.95)], "p99": sorted[ceili(float(sorted.size() - 1) * 0.99)], "max": sorted[-1], "min": sorted[0], "samples": values.size()}

func finish() -> Dictionary:
	var frame_stats := stats(frames)
	var elapsed := float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var details: Dictionary = {}
	for key: String in components:
		details[key] = stats(components[key])
	return {"component_ms": details, "duration_seconds": elapsed, "fps": float(frames.size()) / elapsed, "frame_ms": frame_stats, "simulation_tick_ms": stats(simulation), "grid_tick_ms": stats(grid), "movement_tick_ms": stats(movement), "separation_tick_ms": stats(separation), "render_submission_ms": stats(rendering), "static_memory_mib": stats(memory), "static_memory_first_mib": memory[0] if not memory.is_empty() else 0.0, "static_memory_last_mib": memory[-1] if not memory.is_empty() else 0.0, "raw_frame_ms": Array(frames), "raw_simulation_tick_ms": Array(simulation), "raw_memory_mib": Array(memory)}
