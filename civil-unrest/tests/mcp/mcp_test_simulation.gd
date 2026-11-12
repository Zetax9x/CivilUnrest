extends RefCounted
## Isolated MCP smoke-test simulation; no scene or UI dependencies.
const COUNT: int = 20
const RADIUS: float = 10.0
const CELL_SIZE: float = 40.0
const SPEED: float = 65.0

var positions: PackedVector2Array = PackedVector2Array()
var velocities: PackedVector2Array = PackedVector2Array()
var next_velocities: PackedVector2Array = PackedVector2Array()
var bounds: Rect2 = Rect2(30, 140, 1050, 460)
var ticks: int = 0
var grid: Dictionary = {}

func reset(area: Rect2) -> void:
	bounds = area
	ticks = 0
	grid.clear()
	positions.resize(COUNT)
	velocities.resize(COUNT)
	next_velocities.resize(COUNT)
	for i in range(COUNT):
		var fraction := Vector2((float(i % 5) + 0.5) / 5.0, (float(i / 5) + 0.5) / 4.0)
		positions[i] = bounds.position + fraction * bounds.size
		velocities[i] = Vector2.from_angle(float(i) * 2.399963) * SPEED

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))

func _rebuild_grid() -> void:
	for key: Vector2i in grid:
		var bucket: Array = grid[key]
		bucket.clear()
	for i in range(COUNT):
		var key := _cell(positions[i])
		if not grid.has(key):
			grid[key] = []
		var bucket: Array = grid[key]
		bucket.append(i)

func step(delta: float) -> void:
	_rebuild_grid()
	for i in range(COUNT):
		var force := Vector2.ZERO
		var cell := _cell(positions[i])
		for y in range(-1, 2):
			for x in range(-1, 2):
				var key := cell + Vector2i(x, y)
				if not grid.has(key):
					continue
				var bucket: Array = grid[key]
				for other: int in bucket:
					if other == i:
						continue
					var offset := positions[i] - positions[other]
					var distance := offset.length()
					if distance > 0.001 and distance < CELL_SIZE:
						force += offset / distance * (CELL_SIZE - distance) * 9.0
		var velocity := (velocities[i] + force * delta).limit_length(SPEED)
		if velocity.length() < SPEED * 0.5:
			velocity = velocities[i].normalized() * SPEED * 0.5
		var point := positions[i]
		if point.x <= bounds.position.x and velocity.x < 0.0 or point.x >= bounds.end.x and velocity.x > 0.0:
			velocity.x = -velocity.x
		if point.y <= bounds.position.y and velocity.y < 0.0 or point.y >= bounds.end.y and velocity.y > 0.0:
			velocity.y = -velocity.y
		next_velocities[i] = velocity
	for i in range(COUNT):
		velocities[i] = next_velocities[i]
		positions[i] = (positions[i] + velocities[i] * delta).clamp(bounds.position, bounds.end)
	# Resolve only nearby penetrating pairs; rebuild after corrections.
	for iteration in range(3):
		_rebuild_grid()
		for i in range(COUNT):
			var cell := _cell(positions[i])
			for y in range(-1, 2):
				for x in range(-1, 2):
					var key := cell + Vector2i(x, y)
					if not grid.has(key):
						continue
					var bucket: Array = grid[key]
					for other: int in bucket:
						if other <= i:
							continue
						var offset := positions[i] - positions[other]
						var distance := offset.length()
						if distance < RADIUS * 2.0:
							var normal := offset / distance if distance > 0.001 else Vector2.RIGHT
							var correction := normal * (RADIUS * 2.0 - distance) * 0.5
							positions[i] = (positions[i] + correction).clamp(bounds.position, bounds.end)
							positions[other] = (positions[other] - correction).clamp(bounds.position, bounds.end)
	ticks += 1

func minimum_distance() -> float:
	# Diagnostic only, not used by the simulation's neighbor search.
	var minimum: float = INF
	for i in range(COUNT):
		for j in range(i + 1, COUNT):
			minimum = minf(minimum, positions[i].distance_to(positions[j]))
	return minimum
