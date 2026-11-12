extends SceneTree
const Simulation = preload("res://tests/mcp/mcp_test_simulation.gd")

func _initialize() -> void:
	var first := Simulation.new()
	var second := Simulation.new()
	var area := Rect2(30, 140, 1050, 460)
	first.reset(area)
	second.reset(area)
	if first.positions.size() != 20:
		_fail("agent count")
		return
	var initial: PackedVector2Array = first.positions.duplicate()
	for tick in range(900):
		first.step(1.0 / 30.0)
		second.step(1.0 / 30.0)
		if first.positions != second.positions:
			_fail("determinism")
			return
		for point: Vector2 in first.positions:
			if not point.is_finite() or point.x < area.position.x or point.x > area.end.x or point.y < area.position.y or point.y > area.end.y:
				_fail("finite positions and bounds")
				return
		if first.minimum_distance() < Simulation.RADIUS * 2.0 - 0.1:
			_fail("local separation")
			return
	if first.positions == initial:
		_fail("autonomous movement")
		return
	# An exactly coincident pair must also separate without NaN.
	first.positions[1] = first.positions[0]
	first.step(1.0 / 30.0)
	if first.positions[0].distance_to(first.positions[1]) < Simulation.RADIUS * 2.0 - 0.1:
		_fail("coincident pair separation")
		return
	print("MCP_CHECKS_PASS count=20 ticks=900 determinism movement bounds finite separation coincident_pair")
	quit(0)

func _fail(message: String) -> void:
	push_error("MCP_CHECKS_FAIL " + message)
	quit(1)
