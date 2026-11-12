extends SceneTree
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
const Grid = preload("res://scripts/navigation/spatial_grid.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_check_grid()
	_check_collision()
	if "--grid-only" in OS.get_cmdline_user_args():
		if failures.is_empty():
			print("GRID_CHECKS_PASS unordered pairs unique and complete against brute force")
			quit(0)
		else:
			for failure in failures:
				push_error(failure)
			quit(1)
		return
	for kind: String in ["dispersed", "chokepoint"]:
		for count: int in [100, 300, 500, 1000]:
			var a := Simulation.new()
			var b := Simulation.new()
			a.reset(count, kind)
			b.reset(count, kind)
			var initial := a.state.positions.duplicate()
			var worst_penetration: float = 0.0
			for tick in range(300):
				a.step()
				b.step()
				if a.state.positions != b.state.positions:
					failures.append("Determinism: %s/%d tick %d" % [kind, count, tick])
					break
				for point: Vector2 in a.state.positions:
					if not a.scenario.is_valid(point):
						failures.append("Bounds/obstacle/NaN: %s/%d tick %d" % [kind, count, tick])
						break
				if tick % 30 == 0:
					var diagnostic := a.diagnostics()
					worst_penetration = maxf(worst_penetration, diagnostic["max_penetration"])
			if a.state.count != count or a.state.positions.size() != count:
				failures.append("Population changed")
			if a.state.positions == initial:
				failures.append("No movement")
			if a.ticks != 300:
				failures.append("Fixed tick count mismatch")
			if a.state.crossings == 0:
				failures.append("No traversal: %s/%d" % [kind, count])
			# Swept motion must preserve body clearance within 0.1 unit.
			if worst_penetration > 0.1:
				failures.append("Excessive penetration: %s/%d %.3f" % [kind, count, worst_penetration])
			print("CROWD_CHECK kind=%s count=%d crossings=%d max_penetration=%.4f" % [kind, count, a.state.crossings, worst_penetration])
	if failures.is_empty():
		print("CROWD_CHECKS_PASS grid completeness boundaries determinism population movement obstacles separation traversal")
		quit(0)
	else:
		for failure in failures:
			push_error("CROWD_CHECKS_FAIL " + failure)
		quit(1)

func _check_grid() -> void:
	var grid := Grid.new()
	var points := PackedVector2Array([Vector2(0, 0), Vector2(21.9, 21.9), Vector2(22.1, 22.1), Vector2(1599, 899), Vector2(1590, 895), Vector2(100, 100), Vector2(119, 100)])
	grid.configure(Vector2(1600, 900), points.size())
	grid.rebuild(points)
	for i in range(points.size()):
		var count := grid.gather(points[i])
		var found: Array[int] = []
		for n in range(count):
			found.append(grid.candidates[n])
		for j in range(points.size()):
			if points[i].distance_squared_to(points[j]) <= 400.0 and not found.has(j):
				failures.append("Grid missed near pair %d/%d" % [i, j])

	grid.build_pairs(points)
	var seen: Dictionary = {}
	for n in range(grid.pair_count):
		var i := mini(grid.pair_a[n], grid.pair_b[n])
		var j := maxi(grid.pair_a[n], grid.pair_b[n])
		var key := i * points.size() + j
		if i == j or seen.has(key):
			failures.append("Duplicate or reflexive grid pair")
		seen[key] = true
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			if points[i].distance_squared_to(points[j]) <= 400.0 and not seen.has(i * points.size() + j):
				failures.append("Pair enumeration missed brute-force neighbor")

func _check_collision() -> void:
	var sim := Simulation.new()
	sim.reset(100, "chokepoint")
	sim.state.positions[0] = Vector2(150, 150)
	sim.state.positions[1] = Vector2(150, 150)
	sim.step()
	if sim.state.positions[0].distance_to(sim.state.positions[1]) < 9.9:
		failures.append("Coincident pair not separated")
	# A step into a wall must remain on its original side.
	var constrained := sim.scenario.constrain(Vector2(779, 100))
	if constrained.x > 775.01 or not sim.scenario.is_valid(constrained):
		failures.append("Wall penetration")
	var gate := sim.scenario.constrain(Vector2(800, 450))
	if gate != Vector2(800, 450):
		failures.append("Gate incorrectly blocked")
	var positions_before := sim.state.positions.duplicate()
	var checks_before := sim.grid.candidate_checks
	var diagnostic_a := sim.diagnostics()
	var diagnostic_b := sim.diagnostics()
	if diagnostic_a != diagnostic_b or sim.grid.candidate_checks != checks_before or sim.state.positions != positions_before:
		failures.append("Diagnostics must preserve simulation and counters")
