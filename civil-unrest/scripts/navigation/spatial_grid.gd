extends RefCounted
## Dense linked-cell grid: bounded O(cells + agents) rebuild, no per-query arrays.
const CELL_SIZE: float = 22.0
var columns: int = 0
var rows: int = 0
var heads := PackedInt32Array()
var links := PackedInt32Array()
var candidates := PackedInt32Array()
var neighbor_cells := PackedInt32Array()
var neighbor_counts := PackedInt32Array()
var candidate_checks: int = 0
var occupied := PackedInt32Array()
var occupied_count: int = 0

func configure(size: Vector2, capacity: int) -> void:
	columns = ceili(size.x / CELL_SIZE)
	rows = ceili(size.y / CELL_SIZE)
	heads.resize(columns * rows)
	occupied.resize(columns * rows)
	heads.fill(-1)
	occupied_count = 0
	pair_a.resize(capacity * 32)
	pair_b.resize(capacity * 32)
	pair_buffer_growths = 0
	links.resize(capacity)
	candidates.resize(capacity)
	neighbor_cells.resize(columns * rows * 9)
	neighbor_counts.resize(columns * rows)
	for y in range(rows):
		for x in range(columns):
			var cell := y * columns + x
			var count: int = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and nx < columns and ny >= 0 and ny < rows:
						neighbor_cells[cell * 9 + count] = ny * columns + nx
						count += 1
			neighbor_counts[cell] = count

func cell_of(point: Vector2) -> int:
	return clampi(floori(point.y / CELL_SIZE), 0, rows - 1) * columns + clampi(floori(point.x / CELL_SIZE), 0, columns - 1)

func rebuild(positions: PackedVector2Array) -> void:
	for n in range(occupied_count):
		heads[occupied[n]] = -1
	occupied_count = 0
	for i in range(positions.size()):
		var cell := cell_of(positions[i])
		if heads[cell] == -1:
			occupied[occupied_count] = cell
			occupied_count += 1
		links[i] = heads[cell]
		heads[cell] = i

func gather(point: Vector2) -> int:
	var cell := cell_of(point)
	var count: int = 0
	for n in range(neighbor_counts[cell]):
		var other := heads[neighbor_cells[cell * 9 + n]]
		while other != -1:
			candidates[count] = other
			count += 1
			other = links[other]
	candidate_checks += count
	return count

## Enumerate each unordered neighboring pair once. Reuse buffers across ticks.
var pair_a := PackedInt32Array()
var pair_b := PackedInt32Array()
var pair_count: int = 0
var pair_buffer_growths: int = 0

func build_pairs(positions: PackedVector2Array, radius: float = 20.0) -> void:
	var radius_squared := radius * radius
	assert(radius > 0.0 and radius <= CELL_SIZE)
	pair_count = 0
	if pair_a.is_empty():
		pair_a.resize(links.size() * 32)
		pair_b.resize(links.size() * 32)
	for slot in range(occupied_count):
		var cell := occupied[slot]
		var first := heads[cell]
		if first == -1:
			continue
		var i := first
		while i != -1:
			var point := positions[i]
			var j := links[i]
			while j != -1:
				if point.distance_squared_to(positions[j]) <= radius_squared:
					_add_pair(i, j)
				j = links[j]
			i = links[i]
		for n in range(neighbor_counts[cell]):
			var neighbor := neighbor_cells[cell * 9 + n]
			if neighbor <= cell or heads[neighbor] == -1:
				continue
			i = first
			while i != -1:
				var point := positions[i]
				var j := heads[neighbor]
				while j != -1:
					if point.distance_squared_to(positions[j]) <= radius_squared:
						_add_pair(i, j)
					j = links[j]
				i = links[i]
	candidate_checks += pair_count

func _add_pair(i: int, j: int) -> void:
	if pair_count == pair_a.size():
		pair_a.resize(maxi(32, pair_count * 2))
		pair_b.resize(pair_a.size())
		pair_buffer_growths += 1
	pair_a[pair_count] = i
	pair_b[pair_count] = j
	pair_count += 1
