extends SceneTree
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var results: Array[Dictionary] = []
	for mode: String in ["opposed", "east_only"]:
		var sim := Simulation.new()
		sim.reset(1000, "chokepoint", 20261112)
		if mode == "east_only":
			sim.state.directions.fill(1)
		for tick in range(360):
			sim.step()
			if tick in [119, 239, 359]:
				var blocked := 0
				var cancelled := 0
				var requested_fast := 0
				var goal_blocked := 0
				var force_forward := 0.0
				var actual_speed := 0.0
				var desired_speed := 0.0
				var opposing_contacts := 0
				var same_contacts := 0
				for i in range(sim.state.count):
					if sim.state.blocked_ticks[i] < 30:
						continue
					blocked += 1
					var point: Vector2 = sim.state.positions[i]
					var goal: Vector2 = (sim.scenario.destination(point, sim.state.directions[i], i) - point).normalized()
					var requested: Vector2 = sim.state.velocities[i]
					if requested.dot(goal) <= 0.0:
						cancelled += 1
					if requested.length() > 50.0:
						requested_fast += 1
					force_forward += sim.movement.forces[i].dot(goal)
					actual_speed += point.distance_to(sim.state.previous[i]) * 30.0
					desired_speed += requested.dot(goal)
					if sim.movement._travel_fraction(i, point, goal * (65.0 / 30.0), sim.state.positions, sim.scenario) < 0.01:
						goal_blocked += 1
					for n in range(sim.movement.offsets[i], sim.movement.offsets[i + 1]):
						var j: int = sim.movement.neighbors[n]
						if j > i and point.distance_to(sim.state.positions[j]) <= 10.05:
							if sim.state.directions[i] == sim.state.directions[j]:
								same_contacts += 1
							else:
								opposing_contacts += 1
				var row := sim.diagnostics()
				row.merge({"mode": mode, "blocked_requested_forward_nonpositive": cancelled, "blocked_requested_speed_over_50": requested_fast, "blocked_pure_goal_sweep_stopped": goal_blocked, "blocked_mean_force_forward": force_forward / maxf(1, blocked), "blocked_mean_requested_forward": desired_speed / maxf(1, blocked), "blocked_mean_actual_speed": actual_speed / maxf(1, blocked), "blocked_same_contacts": same_contacts, "blocked_opposed_contacts": opposing_contacts})
				results.append(row)
				print(JSON.stringify(row))
	var path := "res://docs/benchmark_results/flow_diagnosis_current_" + str(Time.get_ticks_usec()) + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	quit()
