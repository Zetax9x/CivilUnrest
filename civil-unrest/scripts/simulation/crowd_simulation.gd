extends RefCounted
const State = preload("res://scripts/simulation/crowd_state.gd")
const Grid = preload("res://scripts/navigation/spatial_grid.gd")
const Movement = preload("res://scripts/simulation/crowd_movement.gd")
const Scenario = preload("res://scripts/simulation/benchmark_scenario.gd")
const FIXED_DELTA: float = 1.0 / 30.0
var state := State.new()
var grid := Grid.new()
var movement := Movement.new()
var scenario := Scenario.new()
var ticks: int = 0
var simulation_usec: int = 0
var grid_usec: int = 0
var movement_usec: int = 0
var separation_usec: int = 0
var rebuild_usec: int = 0
var pairs_usec: int = 0

func reset(count: int, kind: String, random_seed: int = 20261112) -> void:
	assert(count > 0 and count <= 1000)
	state.allocate(count)
	movement.configure(count)
	scenario.configure(kind, count)
	grid.configure(Scenario.WORLD, count)
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var half := ceili(float(count) * 0.5)
	for i in range(count):
		state.positions[i] = scenario.spawn_point(i, count, random)
		state.previous[i] = state.positions[i]
		state.velocities[i] = Vector2.ZERO
		state.directions[i] = 1 if i < half else -1
		state.groups[i] = i % 3
	ticks = 0
	grid.rebuild(state.positions)

func step(delta: float = FIXED_DELTA) -> void:
	var started := Time.get_ticks_usec()
	grid.candidate_checks = 0
	grid.rebuild(state.positions)
	var after_rebuild := Time.get_ticks_usec()
	grid.build_pairs(state.positions)
	var after_grid := Time.get_ticks_usec()
	movement.integrate(state, grid, scenario, delta)
	var after_movement := Time.get_ticks_usec()
	var before_separation := Time.get_ticks_usec()
	movement.separate(state, grid, scenario)
	var finished := Time.get_ticks_usec()
	rebuild_usec = after_rebuild - started
	pairs_usec = after_grid - after_rebuild
	grid_usec = after_grid - started
	movement_usec = after_movement - after_grid
	separation_usec = finished - before_separation
	for i in range(state.count):
		if state.positions[i].distance_squared_to(state.previous[i]) < 0.001111:
			state.blocked_ticks[i] += 1
		else:
			state.blocked_ticks[i] = 0
		if (state.previous[i].x < 800.0 and state.positions[i].x >= 800.0) or (state.previous[i].x >= 800.0 and state.positions[i].x < 800.0):
			state.crossings += 1
			if state.crossed[i] == 0:
				state.crossed[i] = 1
				if state.positions[i].x > state.previous[i].x:
					state.unique_crossings_east += 1
				else:
					state.unique_crossings_west += 1
			else:
				state.repeated_crossings += 1
	ticks += 1
	simulation_usec = Time.get_ticks_usec() - started

func diagnostics() -> Dictionary:
	var step_candidate_checks := grid.candidate_checks
	var invalid: int = 0
	var pairs: int = 0
	var contacts: int = 0
	var penetration_total: float = 0.0
	var blocked: int = 0
	var max_penetration: float = 0.0
	var gate_population: int = 0
	grid.rebuild(state.positions)
	for i in range(state.count):
		if state.blocked_ticks[i] >= 30:
			blocked += 1
		var point := state.positions[i]
		if not scenario.is_valid(point):
			invalid += 1
		if absf(point.x - 800.0) < 100.0:
			gate_population += 1
		var count := grid.gather(point)
		for n in range(count):
			var other := grid.candidates[n]
			if other <= i:
				continue
			var distance := point.distance_to(state.positions[other])
			if distance <= 10.05:
				contacts += 1
			if distance < 9.9:
				pairs += 1
				penetration_total += 10.0 - distance
				max_penetration = maxf(max_penetration, 10.0 - distance)
	grid.candidate_checks = step_candidate_checks
	return {"unique_crossings": state.unique_crossings_east + state.unique_crossings_west, "unique_crossings_east": state.unique_crossings_east, "unique_crossings_west": state.unique_crossings_west, "repeated_crossings": state.repeated_crossings, "mean_penetration": penetration_total / pairs if pairs > 0 else 0.0, "contacts": contacts, "blocked_agents": blocked, "pair_buffer_growths": grid.pair_buffer_growths, "solver_passes": movement.solver_passes, "count": state.count, "ticks": ticks, "invalid_positions": invalid, "overlap_pairs": pairs, "max_penetration": max_penetration, "gate_population": gate_population, "crossings": state.crossings, "candidate_checks": grid.candidate_checks}
