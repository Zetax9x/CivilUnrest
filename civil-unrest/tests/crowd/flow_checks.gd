extends SceneTree
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var counts: Array[int] = [1000]
	var tag := "flow_probe"
	var deterministic := false
	var opposing := false
	var moderate := false
	var total_ticks := 360
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="): tag = argument.get_slice("=", 1)
		elif argument == "--all": counts.assign([100, 300, 500, 600, 800, 1000])
		elif argument == "--determinism": deterministic = true
		elif argument == "--opposing": opposing = true
		elif argument == "--opposing-moderate":
			opposing = true
			moderate = true
		elif argument.begins_with("--ticks="): total_ticks = maxi(360, int(argument.get_slice("=", 1)))
	var results: Array[Dictionary] = []
	var failed := false
	for count in counts:
		var sim := Simulation.new()
		sim.reset(count, "chokepoint", 20261112)
		var twin := Simulation.new()
		if deterministic: twin.reset(count, "chokepoint", 20261112)
		# The normal benchmark already contains two opposed flows. This
		# additional adversarial test places both fronts near the gate.
		if opposing:
			for i in range(count):
				var half := count / 2
				var local_id := i % half
				sim.state.positions[i] = Vector2(600.0 + (local_id % 15) * 10.5 if i < half else 850.0 + (local_id % 15) * 10.5, 280.0 + (local_id / 15) * 10.5)
				if moderate:
					sim.state.positions[i] = Vector2((525.0 if i < half else 850.0) + (local_id % 15) * 15.0, 200.0 + (local_id / 15) * 15.0)
				sim.state.previous[i] = sim.state.positions[i]
				if deterministic:
					twin.state.positions[i] = sim.state.positions[i]
					twin.state.previous[i] = sim.state.positions[i]
		var initial_hash := hash(sim.state.positions)
		var geometry := str(sim.scenario.obstacles)
		var seen := PackedByteArray()
		seen.resize(count)
		var cross_east := 0
		var cross_west := 0
		var repeated := 0
		var max_step := 0.0
		var max_penetration := 0.0
		var minimum_swept := INF
		var backward_steps := 0
		var wall_sweep_violations := 0
		var cpu := 0.0
		var snapshots: Array[Dictionary] = []
		var previous_motion := PackedVector2Array()
		previous_motion.resize(count)
		var window_origins := sim.state.positions.duplicate()
		var window_paths := PackedFloat32Array()
		window_paths.resize(count)
		var velocity_reversals := 0
		var peak_oscillators := 0
		var final_oscillators := 0
		for tick in range(total_ticks):
			sim.step()
			cpu += sim.simulation_usec
			if deterministic:
				twin.step()
				if sim.state.positions != twin.state.positions or sim.state.directions != twin.state.directions:
					push_error("Determinism failed at tick " + str(tick))
					failed = true
			for i in range(count):
				var move: Vector2 = sim.state.positions[i] - sim.state.previous[i]
				max_step = maxf(max_step, move.length())
				window_paths[i] += move.length()
				for box: Rect2 in sim.scenario.obstacles:
					if _segment_hits_box(sim.state.previous[i], sim.state.positions[i], box.grow(4.9)):
						wall_sweep_violations += 1
				if move.length_squared() > 0.001111 and previous_motion[i].length_squared() > 0.001111 and move.dot(previous_motion[i]) < -0.5 * move.length() * previous_motion[i].length():
					velocity_reversals += 1
				previous_motion[i] = move
				if move.x * sim.state.directions[i] < -0.03334: backward_steps += 1
				if (sim.state.previous[i].x < 800.0) != (sim.state.positions[i].x < 800.0):
					if seen[i] != 0: repeated += 1
					else:
						seen[i] = 1
						if move.x > 0.0: cross_east += 1
						else: cross_west += 1
			for n in range(sim.grid.pair_count):
				var i: int = sim.grid.pair_a[n]
				var j: int = sim.grid.pair_b[n]
				var offset: Vector2 = sim.state.previous[i] - sim.state.previous[j]
				var relative: Vector2 = sim.state.positions[i] - sim.state.previous[i] - sim.state.positions[j] + sim.state.previous[j]
				var fraction := clampf(-offset.dot(relative) / relative.length_squared(), 0.0, 1.0) if relative.length_squared() > 0.00000001 else 0.0
				minimum_swept = minf(minimum_swept, (offset + relative * fraction).length())
			if tick % 30 == 29:
				final_oscillators = 0
				for i in range(count):
					if window_paths[i] > 1.0 and sim.state.positions[i].distance_to(window_origins[i]) < 0.25:
						final_oscillators += 1
					window_origins[i] = sim.state.positions[i]
					window_paths[i] = 0.0
				peak_oscillators = maxi(peak_oscillators, final_oscillators)
				var diagnostic := sim.diagnostics()
				max_penetration = maxf(max_penetration, diagnostic["max_penetration"])
				snapshots.append(diagnostic)
				if diagnostic["overlap_pairs"] > 0 or diagnostic["invalid_positions"] > 0:
					push_error("Invalid contact or geometry")
					failed = true
		var final_agents: Array = []
		for i in range(count):
			final_agents.append([sim.state.positions[i].x, sim.state.positions[i].y, sim.state.directions[i], sim.state.blocked_ticks[i], sim.state.velocities[i].x, sim.state.velocities[i].y])
		var result := sim.diagnostics()
		if result["unique_crossings"] != cross_east + cross_west or result["crossings"] != cross_east + cross_west + repeated or result["unique_crossings_east"] != cross_east or result["unique_crossings_west"] != cross_west:
			push_error("Crossing counter disagrees with independent observer")
			failed = true
		result["final_agents"] = final_agents
		result.merge({"unique_crossings": cross_east + cross_west, "east_crossings": cross_east, "west_crossings": cross_west, "repeated_crossings": repeated, "max_step": max_step, "max_observed_penetration": max_penetration, "minimum_swept_distance": minimum_swept, "backward_steps": backward_steps, "cpu_ms_mean_diagnostic": cpu / (total_ticks * 1000.0), "initial_positions_hash": initial_hash, "geometry": geometry, "final_positions_hash": hash(sim.state.positions), "deterministic_replica": deterministic, "opposing_fronts": opposing, "moderate_front_density": moderate, "snapshots": snapshots, "wall_sweep_violations": wall_sweep_violations, "velocity_reversal_events": velocity_reversals, "peak_oscillating_agents": peak_oscillators, "final_oscillating_agents": final_oscillators})
		if max_step > 65.0 / 30.0 + 0.001 or minimum_swept < 9.9 or wall_sweep_violations > 0:
			push_error("Travel bound or swept separation failed")
			failed = true
		# Regression floors preserve useful flow, not the exact measured result:
		# >=250 distinct IDs at 1000 is over nine times the old 27 events.
		if deterministic and not opposing and total_ticks == 360:
			var minimum_transits := {100: 95, 300: 150, 500: 200, 600: 200, 800: 200, 1000: 250}
			if result["unique_crossings"] < minimum_transits[count] or result["blocked_agents"] > 100 or cross_east == 0 or cross_west == 0:
				push_error("Chokepoint throughput regression")
				failed = true
		if opposing and (cross_east < 50 or cross_west < 50):
			push_error("Opposed fronts failed to make progress")
			failed = true
		results.append(result)
		print("FLOW count=%d unique=%d east=%d west=%d blocked=%d swept=%f max_step=%f cpu=%f" % [count, cross_east + cross_west, cross_east, cross_west, result["blocked_agents"], minimum_swept, max_step, cpu / 360000.0])
	var path := "res://docs/benchmark_results/" + tag + ".json"
	if FileAccess.file_exists(path):
		path = path.trim_suffix(".json") + "_" + str(Time.get_ticks_usec()) + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"failed": failed, "results": results}, "\t"))
	file.close()
	print("FLOW_CHECKS_" + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

# Independent segment/rectangle oracle: checks the full rendered chord,
# including the wall corners, rather than reusing the movement sweep.
func _segment_hits_box(start: Vector2, finish: Vector2, box: Rect2) -> bool:
	var movement := finish - start
	var entry := 0.0
	var exit_time := 1.0
	for axis in range(2):
		var origin: float = start[axis]
		var travel: float = movement[axis]
		var low: float = box.position[axis]
		var high: float = box.end[axis]
		if absf(travel) < 0.000001:
			if origin <= low or origin >= high:
				return false
		else:
			var a := (low - origin) / travel
			var b := (high - origin) / travel
			entry = maxf(entry, minf(a, b))
			exit_time = minf(exit_time, maxf(a, b))
			if entry >= exit_time:
				return false
	return entry < exit_time
