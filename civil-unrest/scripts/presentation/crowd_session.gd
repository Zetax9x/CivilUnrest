extends Node
## Owns the existing 2D core. Presentation never writes simulation arrays.
const Simulation = preload("res://scripts/simulation/crowd_simulation.gd")
var simulation := Simulation.new()
var accumulator: float = 0.0
var paused: bool = false
const MAX_CATCHUP_STEPS: int = 4

func configure(count: int, seed_value: int) -> void:
	simulation.reset(count, "dispersed", seed_value)
	accumulator = 0.0

func advance(delta: float) -> void:
	if paused:
		return
	accumulator += delta
	var steps: int = 0
	while accumulator >= Simulation.FIXED_DELTA and steps < MAX_CATCHUP_STEPS:
		simulation.step()
		accumulator -= Simulation.FIXED_DELTA
		steps += 1
	# Preserve debt when a slow frame needs more than four catch-up ticks.

func interpolation() -> float:
	return clampf(accumulator / Simulation.FIXED_DELTA, 0.0, 1.0)
