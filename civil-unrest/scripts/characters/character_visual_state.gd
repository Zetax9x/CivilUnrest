extends RefCounted
## Visual-only state. Inputs are snapshots, never references owned by simulation.
const Poses = preload("res://scripts/characters/character_pose_library.gd")
var count: int = 0
var positions := PackedVector3Array()
var headings := PackedFloat32Array()
var states := PackedInt32Array()
var previous_states := PackedInt32Array()
var phases := PackedFloat32Array()
var previous_phases := PackedFloat32Array()
var blends := PackedFloat32Array()
var speeds := PackedFloat32Array()
var stop_timers := PackedFloat32Array()
var transitions := PackedInt32Array()

func configure(size: int) -> void:
	count = size
	positions.resize(size); headings.resize(size); states.resize(size)
	previous_states.resize(size); phases.resize(size); previous_phases.resize(size)
	blends.resize(size); speeds.resize(size); stop_timers.resize(size); transitions.resize(5)
	transitions.fill(0)
	for i in range(size):
		positions[i] = Vector3.ZERO; headings[i] = 0.0
		states[i] = Poses.State.IDLE; previous_states[i] = Poses.State.IDLE
		phases[i] = float(i % 11) / 11.0; previous_phases[i] = phases[i]
		blends[i] = 1.0; speeds[i] = 0.0; stop_timers[i] = 0.0

func submit(index: int, point: Vector3, velocity: Vector3, desired_heading: float, delta: float) -> void:
	assert(index >= 0 and index < count and delta > 0.0)
	assert(point.is_finite() and velocity.is_finite() and is_finite(desired_heading))
	var speed := Vector2(velocity.x,velocity.z).length()
	var error := wrapf(desired_heading - headings[index], -PI, PI)
	var next := Poses.State.IDLE
	if speed > .08:
		next = Poses.State.RUN if speed > 2.1 else Poses.State.WALK
		stop_timers[index] = 0.0
	elif speeds[index] > .08:
		stop_timers[index] = .38
	elif stop_timers[index] > 0.0:
		stop_timers[index] = maxf(0.0,stop_timers[index]-delta)
	if speed <= .08:
		if stop_timers[index] > 0.0:
			next = Poses.State.STOP
		elif absf(error) > .08:
			next = Poses.State.TURN
	if states[index] != next:
		previous_states[index] = states[index]
		previous_phases[index] = phases[index]
		states[index] = next; blends[index] = 0.0
		transitions[next] += 1
		if next == Poses.State.STOP:
			phases[index] = 0.0
	headings[index] = wrapf(headings[index] + clampf(error,-3.8*delta,3.8*delta),-PI,PI)
	blends[index] = minf(1.0,blends[index] + delta / .16)
	match next:
		Poses.State.WALK: phases[index] = fposmod(phases[index] + speed*delta/1.0,1.0)
		Poses.State.RUN: phases[index] = fposmod(phases[index] + speed*delta/1.6,1.0)
		Poses.State.STOP: phases[index] = minf(1.0,phases[index] + delta/.38)
		_: phases[index] = fposmod(phases[index] + delta * (.9 if next == Poses.State.TURN else .25),1.0)
	positions[index] = point; speeds[index] = speed
