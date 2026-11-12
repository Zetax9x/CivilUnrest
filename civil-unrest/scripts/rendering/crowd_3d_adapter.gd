extends RefCounted
## Read-only map: simulation [0,1600] x [0,900] -> world X/Z [-40,40] x [-22.5,22.5].
const METERS_PER_UNIT: float = 0.05
const ORIGIN := Vector2(800.0, 450.0)

static func to_world(point: Vector2) -> Vector3:
	var ground := (point - ORIGIN) * METERS_PER_UNIT
	return Vector3(ground.x, ground_height(ground.y), ground.y)

static func to_simulation(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z) / METERS_PER_UNIT + ORIGIN

static func ground_height(z: float) -> float:
	# Two shallow ramps connect the plaza pavement to the road without foot clipping.
	return lerpf(0.06, 0.18, clampf((absf(z) - 7.1) / 0.6, 0.0, 1.0))

static func heading(previous: Vector2, current: Vector2, fallback: float) -> float:
	var travel := current - previous
	if travel.length_squared() <= 0.000001:
		return fallback
	# The character's front points along local -Z.
	return atan2(-travel.x, -travel.y)
