extends RefCounted
## Shared immutable pose bank: five states x 32 phases x 14 rigid transforms (including planted feet).
enum State { IDLE, WALK, RUN, TURN, STOP }
const NAMES := ["Idle", "Walk", "Run", "Turn", "Stop"]
const STEPS := 32
const BONES := 14
var bank: Array = []

func _init() -> void:
	for state in range(5):
		var phases: Array = []
		for frame in range(STEPS):
			phases.append(build(state, float(frame) / (STEPS - 1 if state == State.STOP else STEPS)))
		bank.append(phases)

func sample(state: int, phase: float, bone: int) -> Transform3D:
	var frame := phase * (STEPS - 1) if state == State.STOP else fposmod(phase, 1.0) * STEPS
	var first := mini(int(frame), STEPS - 1)
	var second := mini(first + 1, STEPS - 1) if state == State.STOP else (first + 1) % STEPS
	var a: Transform3D = bank[state][first][bone]
	var b: Transform3D = bank[state][second][bone]
	return a.interpolate_with(b, frame - first)

func build(state: int, phase: float) -> Array[Transform3D]:
	var gait := 0.0
	var knee := 0.0
	var arm := 0.0
	var lean := 0.0
	var bob := .006 * sin(phase * TAU)
	match state:
		State.WALK:
			gait = .43; knee = .65; arm = .32
			bob = .015 * (1.0 - cos(phase * TAU * 2))
		State.RUN:
			gait = .78; knee = 1.05; arm = .78; lean = -.12
			bob = .035 * (1.0 - cos(phase * TAU * 2))
		State.TURN:
			gait = .13; knee = .16; arm = .10
		State.STOP:
			gait = .24 * (1.0 - phase); knee = .30 * (1.0 - phase)
			arm = .16 * (1.0 - phase)
			bob = .01 * sin(phase * PI)
	var wave := sin(phase * TAU)
	var bones: Array[Transform3D] = []
	bones.resize(BONES)
	bones[0] = Transform3D.IDENTITY
	var hip_height := .88 + bob - (.055 if state == State.WALK else .10 if state == State.RUN else .0)
	bones[1] = Transform3D(Basis.IDENTITY,Vector3(0,hip_height,0))
	bones[2] = Transform3D(Basis(Vector3.RIGHT,lean), Vector3(0,hip_height,0))
	bones[3] = bones[2] * Transform3D(Basis(Vector3.UP,.12 * wave if state == State.TURN else .025 * wave),Vector3(0,.62,0))
	for side in range(2):
		var sign_value := -1.0 if side == 0 else 1.0
		var swing := wave * sign_value
		var leg := 4 + side * 2
		var shoulder := 8 + side * 2
		var ankle := Vector3(sign_value*.105,.08 + maxf(0.0,swing)*knee*.20,cos(phase*TAU)*sign_value*gait*.48)
		if state == State.WALK or state == State.RUN:
			var cycle := fposmod(phase+side*.5,1.0)
			var stance := .60 if state == State.WALK else .40
			var stride := 1.0 if state == State.WALK else 1.6
			var half_step := stride*stance*.5
			if cycle <= stance:
				ankle.z = -half_step+stride*cycle
				ankle.y = .08
			else:
				var flight := (cycle-stance)/(1.0-stance)
				ankle.z = lerpf(half_step,-half_step,smoothstep(0.0,1.0,flight))
				ankle.y = .08+sin(flight*PI)*(.12 if state == State.WALK else .24)
		var hip := Vector3(sign_value*.105,hip_height,0)
		var offset := ankle - hip
		var reach := minf(offset.length(),.8199)
		var bend := acos(clampf(reach/.82,0.0,1.0))
		var aim := -atan2(offset.z,-offset.y)
		bones[leg] = Transform3D(Basis(Vector3.RIGHT,aim+bend),hip)
		bones[leg+1] = bones[leg] * Transform3D(Basis(Vector3.RIGHT,-2.0*bend),Vector3(0,-.41,0))
		bones[12+side] = Transform3D(Basis.IDENTITY,ankle)
		bones[shoulder] = bones[2] * Transform3D(Basis(Vector3.RIGHT,-arm*swing),Vector3(sign_value*.23,.50,0))
		bones[shoulder+1] = bones[shoulder] * Transform3D(Basis(Vector3.RIGHT,-.10 - (.65 if state == State.RUN else .05)),Vector3(0,-.27,0))
	return bones
