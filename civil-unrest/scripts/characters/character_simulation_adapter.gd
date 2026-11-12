extends RefCounted
## Read-only bridge. Uses achieved displacement, not requested steering velocity.
const Ground = preload("res://scripts/rendering/crowd_3d_adapter.gd")
const Data = preload("res://scripts/simulation/crowd_state.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")

static func submit(visual: Visual, data: Data, alpha: float, frame_delta: float, tick_delta: float) -> void:
	assert(data.count == visual.count and tick_delta > 0.0)
	for i in range(data.count):
		var point := data.previous[i].lerp(data.positions[i],clampf(alpha,0.0,1.0))
		var travel := (data.positions[i] - data.previous[i]) * Ground.METERS_PER_UNIT / tick_delta
		visual.submit(i,Ground.to_world(point),Vector3(travel.x,0,travel.y),
			Ground.heading(data.previous[i],data.positions[i],visual.headings[i]),frame_delta)
