extends RefCounted
## Original modular geometry in metres; forward is -Z, height approximately 1.78 m.
enum Archetype { CIVILIAN, DEMONSTRATOR, POLICE }
const NAMES := ["Civile", "Manifestante", "Polizia"]
const TOPS := ["#68715b", "#8c7569", "#586b78", "#807d72", "#6c5961"]
const LEGS := ["#394750", "#4b4c48", "#343c47", "#58524a"]
const SKINS := ["#b99d86", "#94735e", "#c5aa91", "#795c49"]
const HAIR := ["#39332e", "#685544", "#4b423c", "#867d6a"]
## Bones: root, pelvis, torso, head, left thigh/shin, right thigh/shin, arms/forearms.
static func parts(archetype: int, variant: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var top := Color(TOPS[variant % TOPS.size()])
	var trousers := Color(LEGS[variant % LEGS.size()])
	var skin := Color(SKINS[variant % SKINS.size()])
	var hair := Color(HAIR[variant % HAIR.size()])
	var dark := Color("#292f30")
	if archetype == Archetype.POLICE:
		top = Color("#304758")
		trousers = Color("#293b4d")
	# Each part records a rigid bone binding and the last LOD where it is retained.
	add(out, 1, 1, Vector3.ZERO, Vector3(.34,.22,.25), trousers)
	add(out, 2, 1, Vector3(0,.22,0), Vector3(.43,.58,.29), top)
	add(out, 2, 0, Vector3(0,.045,0), Vector3(.33,.14,.25), top)
	add(out, 3, 1, Vector3(0,.115,0), Vector3(.205,.25,.22), skin)
	add(out, 3, 1, Vector3(0,.195,.01), Vector3(.215,.10,.225), hair, 1)
	add(out, 2, 2, Vector3(0,.53,0), Vector3(.105,.13,.11), skin, 1)
	add(out, 3, 1, Vector3(0,.11,-.12), Vector3(.045,.06,.048), skin, 0)
	for side in [-1.0, 1.0]:
		var thigh: int = 4 if side < 0 else 6
		var arm: int = 8 if side < 0 else 10
		add(out, thigh, 2, Vector3(0,-.20,0), Vector3(.16,.42,.17), trousers)
		add(out, thigh + 1, 2, Vector3(0,-.195,0), Vector3(.13,.39,.14), trousers)
		add(out, 12 + (0 if side < 0 else 1), 1, Vector3(0,-.02,-.055), Vector3(.14,.12,.28), dark)
		add(out, arm, 2, Vector3(0,-.13,0), Vector3(.14,.29,.16), top)
		add(out, arm + 1, 2, Vector3(0,-.12,0), Vector3(.11,.26,.13), top)
		add(out, arm + 1, 1, Vector3(0,-.275,-.015), Vector3(.085,.15,.075), skin, 1)
		add(out, 3, 0, Vector3(side*.042,.13,-.108), Vector3(.017,.009,.012), dark, 0)
	# Clothes have a collar, jacket seam and pockets, readable at close zoom.
	add(out, 2, 0, Vector3(0,.23,-.147), Vector3(.010,.35,.013), Color("#a8a89a"), 0)
	for side in [-1.0,1.0]:
		add(out, 2, 0, Vector3(side*.10,.12,-.142), Vector3(.10,.11,.025), top.darkened(.12), 0)
	if archetype == Archetype.DEMONSTRATOR:
		add(out, 2, 1, Vector3(0,.25,.23), Vector3(.34,.40,.23), Color("#776e54"))
		for side in [-1.0,1.0]:
			add(out, 2, 0, Vector3(side*.14,.27,-.14), Vector3(.045,.39,.025), Color("#494d42"), 1)
		if variant % 2 == 0:
			add(out, 2, 1, Vector3(0,.47,-.01), Vector3(.24,.10,.27), Color("#8c7666"), 1)
		if variant % 3 == 1:
			add(out, 9, 2, Vector3(0,-.26,.01), Vector3(.12,.075,.13), Color("#938368"), 0)
	if archetype == Archetype.POLICE:
		add(out, 2, 0, Vector3(0,.25,-.025), Vector3(.40,.41,.31), Color("#263847"))
		add(out, 3, 1, Vector3(0,.20,.015), Vector3(.265,.22,.275), Color("#344653"))
		add(out, 3, 0, Vector3(0,.145,-.135), Vector3(.26,.04,.08), Color("#667681"), 1)
		add(out, 1, 0, Vector3(0,.025,0), Vector3(.36,.065,.28), dark, 1)
		for side in [-1.0,1.0]:
			add(out, 2, 0, Vector3(side*.135,.30,-.19), Vector3(.085,.12,.045), top.lightened(.10), 0)
			add(out, 2, 0, Vector3(side*.15,.43,-.19), Vector3(.045,.018,.01), Color("#b4b8b1"), 1)
		if variant % 2 == 0:
			add(out, 1, 0, Vector3(.22,.02,0), Vector3(.08,.17,.12), dark, 1)
			add(out, 2, 0, Vector3(-.12,.42,-.20), Vector3(.06,.10,.04), dark, 0)
		if variant % 3 == 1:
			# Optional defensive shield; visual equipment only, no combat semantics.
			add(out, 9, 0, Vector3(-.08,-.13,-.20), Vector3(.40,.66,.045), Color("#6b7c82"), 1)
			add(out, 9, 0, Vector3(-.08,-.13,-.23), Vector3(.38,.16,.015), top, 1)
	return out

static func add(out: Array[Dictionary], bone: int, shape: int, point: Vector3, size: Vector3, color: Color, lod: int = 2) -> void:
	out.append({"bone":bone,"shape":shape,"local":Transform3D(Basis.IDENTITY.scaled_local(size),point),"color":color,"lod":lod})
