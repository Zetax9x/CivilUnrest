extends SceneTree
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
var failures: Array[String] = []
var results: Array[Dictionary] = []

func _initialize() -> void:
	for kind: String in ["high_density", "narrow_passage", "opposing_flows", "temporary_block"]:
		_check(kind)
	var output := {"seed": 20261112, "ticks": 240, "radius": 5.0, "overlap_threshold": 0.1, "failures": failures, "results": results}
	var path := "res://docs/benchmark_results/flow_contact_checks.json"
	if FileAccess.file_exists(path):
		path = path.trim_suffix(".json") + "_" + str(Time.get_ticks_usec()) + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	for failure in failures:
		push_error(failure)
	print("CONTACT_CHECKS_PASS" if failures.is_empty() else "CONTACT_CHECKS_FAIL")
	quit(0 if failures.is_empty() else 1)

func _check(kind: String) -> void:
	var sim := Simulation.new()
	var replica := Simulation.new()
	var count := 1000 if kind == "narrow_passage" else 100
	sim.reset(count, "chokepoint" if kind == "narrow_passage" else "dispersed")
	if kind == "high_density":
		for i in range(count):
			sim.state.positions[i] = Vector2(600 + (i % 10) * 10.2, 400 + (i / 10) * 10.2)
	elif kind == "opposing_flows":
		for i in range(count):
			var local_index := i % 50
			sim.state.positions[i] = Vector2(650 + (local_index % 5) * 11 + (110 if i >= 50 else 0), 360 + (local_index / 5) * 11)
	elif kind == "temporary_block":
		for i in range(10):
			sim.state.positions[i] = Vector2(730, 350 + i * 11)
			sim.state.mobility[i] = 0.0
		for i in range(10, count):
			sim.state.positions[i] = Vector2(620 + (i % 10) * 10.5, 350 + ((i - 10) / 10) * 11)
			sim.state.directions[i] = 1
	replica.reset(count, sim.scenario.kind)
	replica.state.positions = sim.state.positions.duplicate()
	replica.state.directions = sim.state.directions.duplicate()
	replica.state.mobility = sim.state.mobility.duplicate()
	var pinned := sim.state.positions.duplicate()
	var released := Vector2.ZERO
	var max_penetration: float = 0.0
	var sum_penetration: float = 0.0
	var overlap_samples: int = 0
	var peak_contacts: int = 0
	var peak_blocked: int = 0
	var max_step_ms: float = 0.0
	var cpu_total: float = 0.0
	var worst_swept: float = 10.0
	var all_pairs_validated: int = 0
	for tick in range(240):
		if kind == "temporary_block" and tick == 90:
			released = sim.state.positions[0]
			sim.state.mobility.fill(1.0)
			replica.state.mobility.fill(1.0)
		sim.step()
		replica.step()
		cpu_total += sim.simulation_usec / 1000.0
		max_step_ms = maxf(max_step_ms, sim.simulation_usec / 1000.0)
		if sim.state.positions != replica.state.positions:
			failures.append(kind + ": nondeterministic")
			break
		if kind == "temporary_block" and tick < 90:
			for i in range(10):
				if sim.state.positions[i] != pinned[i]:
					failures.append("Pinned agent moved")
		var diagnostic := sim.diagnostics()
		if diagnostic["invalid_positions"] > 0:
			for i in range(count):
				if not sim.scenario.is_valid(sim.state.positions[i]):
					failures.append("%s: invalid tick=%d id=%d previous=%s current=%s" % [kind, tick, i, sim.state.previous[i], sim.state.positions[i]])
			break
		max_penetration = maxf(max_penetration, diagnostic["max_penetration"])
		sum_penetration += diagnostic["mean_penetration"] * diagnostic["overlap_pairs"]
		overlap_samples += diagnostic["overlap_pairs"]
		peak_contacts = maxi(peak_contacts, diagnostic["contacts"])
		peak_blocked = maxi(peak_blocked, diagnostic["blocked_agents"])
		# Independent exhaustive oracle for the 100-agent stress fixtures.
		# Also verify swept relative motion, not only endpoints (no tunnelling).
		if count == 100 or tick % 60 == 0 or tick == 239:
			for i in range(count):
				for j in range(i + 1, count):
					var distance := sim.state.positions[i].distance_to(sim.state.positions[j])
					if distance < 9.9:
						failures.append(kind + ": excessive oracle penetration")
						break
					if kind == "opposing_flows":
						var start := sim.state.previous[i] - sim.state.previous[j]
						var finish := sim.state.positions[i] - sim.state.positions[j]
						var relative := finish - start
						var t := clampf(-start.dot(relative) / relative.length_squared(), 0.0, 1.0) if relative.length_squared() > 0.000001 else 0.0
						worst_swept = minf(worst_swept, (start + relative * t).length())
					all_pairs_validated += 1
	if max_penetration > 0.1:
		failures.append("%s max penetration %.4f exceeds 0.1 unit" % [kind, max_penetration])
	if kind == "opposing_flows" and worst_swept < 9.9:
		failures.append("Opposing agents crossed or exceeded swept tolerance")
	if kind == "temporary_block" and sim.state.positions[0].distance_to(released) < 10.0:
		failures.append("Temporarily blocked agent failed to resume")
	var result := {"scenario": kind, "count": count, "max_penetration": max_penetration, "mean_penetration_over_overlapping_pairs": sum_penetration / overlap_samples if overlap_samples > 0 else 0.0, "overlap_pair_tick_samples": overlap_samples, "peak_contacts": peak_contacts, "peak_blocked_agents": peak_blocked, "swept_min_distance": worst_swept if kind == "opposing_flows" else null, "oracle_pairs_checked": all_pairs_validated, "mean_cpu_ms": cpu_total / 240.0, "max_cpu_ms": max_step_ms, "crossings": sim.state.crossings}
	results.append(result)
	print("CONTACT_CHECK " + JSON.stringify(result))
