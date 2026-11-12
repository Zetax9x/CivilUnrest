extends Node2D
const State = preload("res://scripts/simulation/crowd_state.gd")
const Scenario = preload("res://scripts/simulation/benchmark_scenario.gd")
var state: State
var scenario: Scenario
var alpha: float = 0.0
var submission_usec: int = 0
var texture: ImageTexture
var colors := PackedColorArray()
var use_multimesh: bool = false
@onready var instances: MultiMeshInstance2D = $Instances

func configure(data: State, map: Scenario, instanced: bool = false) -> void:
	state = data
	scenario = map
	use_multimesh = instanced
	if texture == null:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in range(16):
			for x in range(16):
				if Vector2(x - 7.5, y - 7.5).length_squared() <= 56.25:
					image.set_pixel(x, y, Color.WHITE)
		texture = ImageTexture.create_from_image(image)
	colors.resize(state.count)
	var palette: Array[Color] = [Color("#56d9ce"), Color("#f3be5a"), Color("#ab8bf5")]
	for i in range(state.count):
		colors[i] = palette[state.groups[i]]
	var mesh := QuadMesh.new()
	mesh.size = Vector2(10, 10)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = state.count
	multimesh.custom_aabb = AABB(Vector3.ZERO, Vector3(1600, 900, 1))
	instances.multimesh = multimesh
	instances.texture = texture
	instances.visible = use_multimesh
	for i in range(state.count):
		multimesh.set_instance_color(i, colors[i])
	queue_redraw()

func present(fraction: float) -> void:
	alpha = clampf(fraction, 0.0, 1.0)
	if use_multimesh:
		var started := Time.get_ticks_usec()
		for i in range(state.count):
			var point := state.previous[i].lerp(state.positions[i], alpha)
			instances.multimesh.set_instance_transform_2d(i, Transform2D(0.0, point))
		submission_usec = Time.get_ticks_usec() - started
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Scenario.WORLD), Color("#101824"))
	draw_rect(Rect2(20, 20, 1560, 860), Color("#243249"), false, 2)
	if state == null:
		return
	for obstacle in scenario.obstacles:
		draw_rect(obstacle, Color("#536277"))
	if not use_multimesh:
		var started := Time.get_ticks_usec()
		for i in range(state.count):
			var point := state.previous[i].lerp(state.positions[i], alpha)
			draw_texture_rect(texture, Rect2(point - Vector2(5, 5), Vector2(10, 10)), false, colors[i])
		submission_usec = Time.get_ticks_usec() - started
