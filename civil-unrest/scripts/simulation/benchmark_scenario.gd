extends RefCounted
const WORLD := Vector2(1600, 900)
const RADIUS: float = 5.0
const SPEED: float = 65.0
var kind: String = "dispersed"
var lane_offsets := PackedFloat32Array()
var obstacles: Array[Rect2] = []
var expanded_obstacles: Array[Rect2] = []

func configure(value: String, count: int = 1000) -> void:
	kind = value
	lane_offsets.resize(count)
	# Assign contiguous spawn rows to ordered lanes once, without per-tick
	# square roots, ID shuffling, or additional simulation nodes.
	var half := ceili(float(count) * 0.5)
	var columns := ceili(sqrt(float(half) * 0.65))
	var rows := ceili(float(half) / float(columns))
	for i in range(count):
		var row := (i % half) / columns
		lane_offsets[i] = mini(4, floori(float(row) * 5.0 / float(rows))) * 10.5
	obstacles.clear()
	if kind == "chokepoint":
		obstacles.append(Rect2(780, 20, 40, 350))
		obstacles.append(Rect2(780, 530, 40, 350))

	refresh_obstacles()

func refresh_obstacles() -> void:
	expanded_obstacles.clear()
	for obstacle in obstacles:
		expanded_obstacles.append(obstacle.grow(RADIUS))

func spawn_point(index: int, count: int, random: RandomNumberGenerator) -> Vector2:
	var half := ceili(float(count) * 0.5)
	var local_index := index % half
	var columns := ceili(sqrt(float(half) * 0.65))
	var rows := ceili(float(half) / float(columns))
	var left := index < half
	var origin := Vector2(60 if left else 850, 70)
	var size := Vector2(690, 760)
	if kind == "chokepoint":
		origin.x = 400 if left else 850
		size.x = 350
	return origin + Vector2(
		(float(local_index % columns) + 0.5) / float(columns) * size.x,
		(float(floori(float(local_index) / float(columns))) + 0.5) / float(rows) * size.y
	) + Vector2(random.randf_range(-1, 1), random.randf_range(-1, 1))

func destination(point: Vector2, direction: int, index: int) -> Vector2:
	if kind == "chokepoint":
		# Leave the shared mouth clear while forming ordered lanes upstream.
		# A short outward waypoint lets the outgoing stream pass; advancing
		# or merely aligning in place traps dense opposed fronts.
		# Targets follow spawn-row order, avoiding same-flow weaving.
		var lane_y := (390.0 if direction > 0 else 470.0) + lane_offsets[index]
		var approaching := point.x < 775.0 if direction > 0 else point.x > 825.0
		var outside_band := point.y < (380.0 if direction > 0 else 460.0) or point.y > (440.0 if direction > 0 else 520.0)
		if approaching and outside_band:
			return Vector2(point.x - 20.0 if direction > 0 else point.x + 20.0, lane_y)
		# Keep the outgoing flow apart from the incoming approach.
		return Vector2(1530.0 if direction > 0 else 70.0, lane_y)
	return Vector2(1530 if direction > 0 else 70, 80.0 + float((index * 73) % 740))

func constrain(point: Vector2) -> Vector2:
	var result := point.clamp(Vector2(20 + RADIUS, 20 + RADIUS), WORLD - Vector2(20 + RADIUS, 20 + RADIUS))
	# Most agents never touch the central wall; expanded bounds are cached.
	for expanded in expanded_obstacles:
		if expanded.has_point(result):
			var distances := Vector4(result.x - expanded.position.x, expanded.end.x - result.x, result.y - expanded.position.y, expanded.end.y - result.y)
			var nearest := minf(minf(distances.x, distances.y), minf(distances.z, distances.w))
			if nearest == distances.x:
				result.x = expanded.position.x - 0.001
			elif nearest == distances.y:
				result.x = expanded.end.x + 0.001
			elif nearest == distances.z:
				result.y = expanded.position.y - 0.001
			else:
				result.y = expanded.end.y + 0.001
	return result

func is_valid(point: Vector2) -> bool:
	if not point.is_finite() or point.x < 25.0 or point.x > 1575.0 or point.y < 25.0 or point.y > 875.0:
		return false
	for obstacle in obstacles:
		if obstacle.grow(RADIUS - 0.01).has_point(point):
			return false
	return true
