extends SceneTree
const Catalog = preload("res://scripts/characters/character_catalog.gd")
const Poses = preload("res://scripts/characters/character_pose_library.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Data = preload("res://scripts/simulation/crowd_state.gd")
var checks: int = 0
var failures: Array[String] = []
var maximum_ankle_gap: float = 0.0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value and failures.size() < 12:
		failures.append(message)

func _initialize() -> void:
	var poses := Poses.new()
	for state in range(5):
		for frame in range(65):
			var phase := float(frame)/64.0
			for bone in range(Poses.BONES):
				var transform := poses.sample(state,phase,bone)
				expect(transform.origin.is_finite() and is_finite(transform.basis.determinant()),"Finite pose")
			for side in range(2):
				var shin := poses.sample(state,phase,5+side*2)
				var ankle := poses.sample(state,phase,12+side)
				var gap := (shin*Vector3(0,-.41,0)).distance_to(ankle.origin)
				maximum_ankle_gap = maxf(maximum_ankle_gap,gap)
				expect(gap < .022,"Leg reach/gap state=%d phase=%f gap=%f" % [state,phase,gap])
				expect(ankle.origin.y-.08 >= -.0001,"Foot below ground")
	expect(not poses.sample(Poses.State.WALK,.0,4).is_equal_approx(poses.sample(Poses.State.WALK,.25,4)),"Walk pose changes")
	expect(not poses.sample(Poses.State.RUN,.25,8).is_equal_approx(poses.sample(Poses.State.WALK,.25,8)),"Run distinct")
	for state in [Poses.State.WALK,Poses.State.RUN]:
		var stride := 1.0 if state == Poses.State.WALK else 1.6
		var foot_a := poses.sample(state,.10,12).origin
		var foot_b := poses.sample(state,.11,12).origin + Vector3(0,0,-stride*.01)
		expect(foot_a.distance_to(foot_b) < .002,"Stance foot remains planted")
	for type in range(3):
		for variant in range(5):
			var parts := Catalog.parts(type,variant)
			expect(parts.size() > 20,"Complete modular archetype")
			for part in parts:
				expect(part.bone >= 0 and part.bone < Poses.BONES and part.lod >= 0 and part.lod <= 2,"Bindings")
	var visual := Visual.new()
	visual.configure(1)
	visual.submit(0,Vector3.ZERO,Vector3.ZERO,0.0,1.0/60)
	expect(visual.states[0] == Poses.State.IDLE,"Idle")
	visual.submit(0,Vector3(0,0,-.02),Vector3(0,0,-1),0.0,1.0/60)
	expect(visual.states[0] == Poses.State.WALK,"Idle to Walk")
	visual.submit(0,Vector3(0,0,-.06),Vector3(0,0,-2.5),0.0,1.0/60)
	expect(visual.states[0] == Poses.State.RUN,"Walk to Run")
	visual.submit(0,Vector3(0,0,-.06),Vector3.ZERO,0.0,1.0/60)
	expect(visual.states[0] == Poses.State.STOP,"Run to Stop")
	for tick in range(40):
		visual.submit(0,Vector3(0,0,-.06),Vector3.ZERO,0.0,1.0/60)
	expect(visual.states[0] == Poses.State.IDLE,"Stop to Idle")
	visual.submit(0,Vector3.ZERO,Vector3.ZERO,PI/2.0,1.0/60)
	expect(visual.states[0] == Poses.State.TURN,"Idle to Turn")
	expect(absf(visual.headings[0]) <= 3.8/60.0+.0001,"Bounded yaw speed")
	for tick in range(60):
		visual.submit(0,Vector3.ZERO,Vector3.ZERO,PI/2.0,1.0/60)
	expect(visual.states[0] == Poses.State.IDLE,"Turn to Idle")
	var data := Data.new(); data.allocate(1)
	data.previous[0] = Vector2(800,450); data.positions[0] = Vector2(802,450)
	data.velocities[0] = Vector2.ZERO # Deliberately inconsistent requested steering.
	var before := data.positions.duplicate()
	var previous := data.previous.duplicate()
	Bridge.submit(visual,data,.5,1.0/60,1.0/30)
	expect(visual.positions[0].is_equal_approx(Vector3(.05,.06,0)),"Coordinate map/interpolation")
	expect(is_equal_approx(visual.speeds[0],3.0),"Achieved displacement drives animation")
	expect(before == data.positions and previous == data.previous and data.velocities[0] == Vector2.ZERO,"Core inputs untouched")
	data.previous[0] = data.positions[0]
	data.velocities[0] = Vector2(100,0)
	Bridge.submit(visual,data,1.0,1.0/60,1.0/30)
	expect(is_zero_approx(visual.speeds[0]),"Blocked agent must not walk on requested velocity")
	var replica := Visual.new()
	visual.configure(20); replica.configure(20)
	for tick in range(240):
		for i in range(20):
			var velocity := Vector3(0,0,-1 if tick < 60 else -2.5 if tick < 120 else 0)
			var point := Vector3(i,0,-tick*.01)
			visual.submit(i,point,velocity,.5,1.0/60)
			replica.submit(i,point,velocity,.5,1.0/60)
	expect(visual.positions == replica.positions and visual.headings == replica.headings and visual.states == replica.states and visual.phases == replica.phases,"Repeatable visual update sequence")
	visual.configure(10)
	expect(visual.count == 10 and visual.positions.size() == 10,"Population reset")
	var packed: PackedScene = load("res://scenes/art_tests/CharacterShowcase.tscn")
	expect(packed != null and packed.can_instantiate(),"Showcase loads")
	var result := {"checks":checks,"failures":failures,"maximum_ankle_gap_m":maximum_ankle_gap,"passed":failures.is_empty()}
	var file := FileAccess.open("res://docs/screenshots/characters/logic_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
