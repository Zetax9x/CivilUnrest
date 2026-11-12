extends SceneTree
const Session = preload("res://scripts/presentation/crowd_session.gd")
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")
const Ground = preload("res://scripts/rendering/crowd_3d_adapter.gd")
var failures: Array[String] = []
var checks: int = 0
var emitted: int = 0
func require(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
func _initialize() -> void:
	for kind: String in ["dispersed","chokepoint"]:
		for count: int in [20,100]:
			var session := Session.new()
			var reference := Simulation.new()
			var visual := Visual.new()
			session.configure(count,20261112,kind)
			reference.reset(count,kind,20261112)
			visual.configure(count)
			session.tick_completed.connect(func(_a: int,_b: int,_c: int,_d: int) -> void: emitted += 1)
			for tick in range(240):
				reference.step()
				session.advance(Simulation.FIXED_DELTA)
				require(session.simulation.state.positions == reference.state.positions,"Exact core replay")
				var before := session.simulation.state.positions.duplicate()
				for alpha: float in [0.0,.5,1.0]:
					Bridge.submit(visual,session.simulation.state,alpha,1.0/60.0,Simulation.FIXED_DELTA)
					var expected := Ground.to_world(session.simulation.state.previous[0].lerp(before[0],alpha))
					require(visual.positions[0].is_equal_approx(expected),"Interpolated 2D/3D position")
				require(before == session.simulation.state.positions,"Adapter read only")
				if tick == 239:
					var diagnostics := session.simulation.diagnostics()
					require(diagnostics.invalid_positions == 0 and diagnostics.overlap_pairs == 0,"Core bounds/separation")
			session.paused = true
			var saved := session.simulation.state.positions.duplicate()
			session.advance(1.0)
			require(saved == session.simulation.state.positions and session.simulation.ticks == 240,"Pause freezes core")
			session.configure(count,20261112,kind)
			require(session.accumulator == 0.0 and session.simulation.ticks == 0,"Reset clears debt")
			session.free()
	require(emitted == 960,"Exactly one observer event per completed tick")
	var debt := Session.new()
	debt.configure(20,20261112)
	debt.advance(.3)
	require(debt.simulation.ticks == 4 and debt.accumulator > .16,"Catchup cap preserves debt")
	debt.advance(.000001)
	debt.advance(.000001)
	require(debt.simulation.ticks == 9 and debt.accumulator < .00001,"Debt recovered without tick loss")
	debt.free()
	var packed := load("res://scenes/benchmarks/UrbanCrowd3D.tscn") as PackedScene
	require(packed != null and packed.can_instantiate(),"Integration scene load")
	var output := {"checks":checks,"failures":failures,"passed":failures.is_empty(),"tick_observations":emitted}
	var file := FileAccess.open("res://docs/urban_crowd_3d/integration_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t")); file.close()
	print(JSON.stringify(output))
	quit(0 if failures.is_empty() else 1)
