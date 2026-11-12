extends RefCounted
const State = preload("res://scripts/simulation/crowd_state.gd")
const Grid = preload("res://scripts/navigation/spatial_grid.gd")
const Scenario = preload("res://scripts/simulation/benchmark_scenario.gd")
const CONTACT_PASSES: int = 16
const CONTACT_TOLERANCE: float = 0.05
# Conservative clearance for linearly interpolated positions between fixed ticks.
# Physical body diameter remains 10; no geometry or overlap tolerance is relaxed.
const TRAVEL_CLEARANCE_SQUARED: float = 104.04 # 10.2 * 10.2
var forces := PackedVector2Array()
var contact_a := PackedInt32Array()
var contact_b := PackedInt32Array()
var contact_count: int = 0
var collision_corrections: int = 0
var avoidance_usec: int = 0
var positions_usec: int = 0
var solver_passes: int = 0
var offsets := PackedInt32Array()
var degrees := PackedInt32Array()
var cursors := PackedInt32Array()
var neighbors := PackedInt32Array()
var tick_index: int = 0

func configure(count: int) -> void:
	forces.resize(count)
	offsets.resize(count + 1)
	degrees.resize(count)
	cursors.resize(count)
	neighbors.resize(count * 64)
	tick_index = 0
	contact_a.resize(count * 32)
	contact_b.resize(count * 32)

func integrate(state: State, grid: Grid, scenario: Scenario, delta: float) -> void:
	var started := Time.get_ticks_usec()
	var positions := state.positions
	var pair_a := grid.pair_a
	var pair_b := grid.pair_b
	forces.fill(Vector2.ZERO)
	degrees.fill(0)
	for n in range(grid.pair_count):
		var i := pair_a[n]
		var j := pair_b[n]
		degrees[i] += 1
		degrees[j] += 1
		var offset := positions[i] - positions[j]
		var squared := offset.length_squared()
		if squared < 400.0 and squared > 0.000001:
			var distance := sqrt(squared)
			var force := offset / distance * (20.0 - distance) * 12.0
			forces[i] += force
			forces[j] -= force
	offsets[0] = 0
	for i in range(state.count):
		offsets[i + 1] = offsets[i] + degrees[i]
		cursors[i] = offsets[i]
	if offsets[state.count] > neighbors.size():
		neighbors.resize(offsets[state.count])
	for n in range(grid.pair_count):
		var i := pair_a[n]
		var j := pair_b[n]
		neighbors[cursors[i]] = j
		neighbors[cursors[j]] = i
		cursors[i] += 1
		cursors[j] += 1
	var after_avoidance := Time.get_ticks_usec()
	avoidance_usec = after_avoidance - started
	for i in range(state.count):
		var point := positions[i]
		state.previous[i] = point
		if point.x > 1510.0:
			state.directions[i] = -1
		elif point.x < 90.0:
			state.directions[i] = 1
		var desired := (scenario.destination(point, state.directions[i], i) - point).normalized() * Scenario.SPEED
		var velocity := (desired + forces[i]).limit_length(Scenario.SPEED) * state.mobility[i]
		state.next_velocities[i] = velocity
		state.velocities[i] = velocity
	# Resolve travel against stationary current neighbor positions. Each move
	# is at most SPEED*delta; the 20-unit list covers diameter+2*travel.
	# Alternating stable ID order avoids permanently prioritizing one faction.
	for slot in range(state.count):
		var i := slot if tick_index % 2 == 0 else state.count - 1 - slot
		if state.mobility[i] <= 0.0:
			continue
		var point := positions[i]
		var displacement := (point + state.velocities[i] * delta).clamp(Vector2(25, 25), Vector2(1575, 875)) - point
		var fraction := _travel_fraction(i, point, displacement, positions, scenario)
		point += displacement * fraction
		if fraction < 1.0:
			# Remaining desired travel projected onto the tangent at first contact.
			var remainder := displacement * (1.0 - fraction)
			var normal := blocking_normal
			remainder -= normal * minf(0.0, remainder.dot(normal))
			remainder = (point + remainder).clamp(Vector2(25, 25), Vector2(1575, 875)) - point
			point += remainder * _travel_fraction(i, point, remainder, positions, scenario)
		positions[i] = point
	tick_index += 1
	positions_usec = Time.get_ticks_usec() - after_avoidance

func separate(state: State, grid: Grid, scenario: Scenario) -> void:
	collision_corrections = 0
	solver_passes = 0
	var positions := state.positions
	var mobility := state.mobility
	# Reuse the pre-movement 20-unit pairs (diameter + 10-unit skin).
	# Fixed 30 Hz travel is <= 2.167 per agent; all potential contacts
	# fit in this list. Refresh after four recovery passes:
	# projection can introduce new contacts, so never rely on stale pairs alone.
	for pass_index in range(CONTACT_PASSES):
		if pass_index % 4 == 0:
			if pass_index > 0:
				grid.rebuild(positions)
				grid.build_pairs(positions, 20.0)
			contact_count = grid.pair_count
			if contact_count > contact_a.size():
				contact_a.resize(contact_count)
				contact_b.resize(contact_count)
			for n in range(contact_count):
				contact_a[n] = grid.pair_a[n]
				contact_b[n] = grid.pair_b[n]
		var worst: float = 0.0
		# Alternate pair order deterministically, reducing directional bias.
		for slot in range(contact_count):
			var n := slot if pass_index % 2 == 0 else contact_count - 1 - slot
			var i := contact_a[n]
			var j := contact_b[n]
			var offset := positions[i] - positions[j]
			var squared := offset.length_squared()
			if squared >= 100.0:
				continue
			var mass := mobility[i] + mobility[j]
			if mass <= 0.0:
				continue
			var distance := sqrt(squared)
			var penetration := 10.0 - distance
			worst = maxf(worst, penetration)
			if penetration <= CONTACT_TOLERANCE:
				continue
			var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
			var correction := normal * penetration / mass
			if mobility[i] > 0.0:
				positions[i] = scenario.constrain(positions[i] + correction * mobility[i])
			if mobility[j] > 0.0:
				positions[j] = scenario.constrain(positions[j] - correction * mobility[j])
			collision_corrections += 1
		solver_passes += 1
		if worst <= CONTACT_TOLERANCE:
			break

var blocking_normal := Vector2.ZERO

func _travel_fraction(index: int, point: Vector2, travel: Vector2, positions: PackedVector2Array, scenario: Scenario) -> float:
	var length_squared := travel.length_squared()
	if length_squared < 0.00000001:
		return 1.0
	var earliest: float = 1.0
	blocking_normal = Vector2.ZERO
	for n in range(offsets[index], offsets[index + 1]):
		var other := neighbors[n]
		var offset := point - positions[other]
		var approach := offset.dot(travel)
		if approach >= 0.0:
			continue
		# Additional clearance protects presentation between endpoint positions.
		var gap_squared := offset.length_squared() - TRAVEL_CLEARANCE_SQUARED
		var discriminant := approach * approach - length_squared * gap_squared
		if discriminant < 0.0:
			continue
		var impact := maxf(0.0, (-approach - sqrt(discriminant)) / length_squared)
		if impact < earliest:
			earliest = impact
			blocking_normal = (offset + travel * impact).normalized()
	for box: Rect2 in scenario.expanded_obstacles:
		var near_x: float = -INF
		var far_x: float = INF
		var near_y: float = -INF
		var far_y: float = INF
		if absf(travel.x) < 0.000001:
			if point.x <= box.position.x or point.x >= box.end.x:
				continue
		else:
			var a := (box.position.x - point.x) / travel.x
			var b := (box.end.x - point.x) / travel.x
			near_x = minf(a, b)
			far_x = maxf(a, b)
		if absf(travel.y) < 0.000001:
			if point.y <= box.position.y or point.y >= box.end.y:
				continue
		else:
			var a := (box.position.y - point.y) / travel.y
			var b := (box.end.y - point.y) / travel.y
			near_y = minf(a, b)
			far_y = maxf(a, b)
		var entry := maxf(near_x, near_y)
		var exit_time := minf(far_x, far_y)
		if entry >= 0.0 and entry <= exit_time and entry < earliest:
			earliest = maxf(0.0, entry - 0.0001)
			blocking_normal = Vector2(-signf(travel.x), 0) if near_x >= near_y else Vector2(0, -signf(travel.y))
	return earliest
