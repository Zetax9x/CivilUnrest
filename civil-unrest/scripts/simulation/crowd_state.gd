extends RefCounted
## Stable IDs equal array indices for this fixed-population milestone.
var count: int = 0
var positions := PackedVector2Array()
var previous := PackedVector2Array()
## Requested steering velocity; actual motion is (positions - previous) / delta.
var velocities := PackedVector2Array()
var next_velocities := PackedVector2Array()
var directions := PackedInt32Array()
var groups := PackedInt32Array()
var crossings: int = 0
# Crossing events and distinct IDs are separate: gate-line chatter must
# never masquerade as increased transport capacity.
var crossed := PackedByteArray()
var unique_crossings_east: int = 0
var unique_crossings_west: int = 0
var repeated_crossings: int = 0
## 0 = temporarily pinned; contact response moves only mobile agents.
var mobility := PackedFloat32Array()
var blocked_ticks := PackedInt32Array()

func allocate(size: int) -> void:
	mobility.resize(size)
	mobility.fill(1.0)
	blocked_ticks.resize(size)
	blocked_ticks.fill(0)
	count = size
	positions.resize(size)
	previous.resize(size)
	velocities.resize(size)
	next_velocities.resize(size)
	directions.resize(size)
	groups.resize(size)
	crossings = 0
	crossed.resize(size)
	crossed.fill(0)
	unique_crossings_east = 0
	unique_crossings_west = 0
	repeated_crossings = 0
