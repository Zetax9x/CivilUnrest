extends Node3D
## Centralized renderer: three MultiMesh batches, zero per-character nodes.
## Per-frame path (measured, see docs/URBAN_CROWD_3D.md):
## - poses are resampled at LOD-dependent rates, staggered across characters;
## - a full part update (pose x heading) happens only on a pose tick or a visible heading change;
## - otherwise only the 3 origin floats of each part follow the interpolated position;
## - unmoved characters are skipped; each batch is uploaded with one multimesh_set_buffer call.
const Catalog = preload("res://scripts/characters/character_catalog.gd")
const Poses = preload("res://scripts/characters/character_pose_library.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Data = preload("res://scripts/simulation/crowd_state.gd")
const POSE_HZ := [60.0, 30.0, 10.0]
## Heading drift (radians) tolerated between full updates; LOD 0 refreshes every frame anyway.
## Worst case lateral error of a part 0.3 m from the axis: LOD 1 (<=23.6 px/m) 0.35 px,
## LOD 2 (<=12.4 px/m) 0.56 px, i.e. sub-pixel. Heading is always resynchronized on pose ticks.
const HEADING_TOLERANCE := [0.0, .05, .15]
const STRIDE: int = 16 # 12 transform floats + 4 color floats per instance
const EPSILON: float = .00001
var visual := Visual.new()
var poses := Poses.new()
var archetypes := PackedInt32Array()
var variants := PackedInt32Array()
var scales := PackedFloat32Array()
var bone_cache: Array = [] # Owned, interpolated bones (LOD 0/1).
var current_pose: Array = [] # Bones used by the last full update (owned array or shared bank frame).
var clocks := PackedFloat32Array()
var written_positions := PackedVector3Array()
var written_headings := PackedFloat32Array()
var part_start := PackedInt32Array()
var part_shape := PackedInt32Array()
var part_slot := PackedInt32Array()
var part_bone := PackedInt32Array()
var part_local: Array[Transform3D] = []
var part_origin := PackedVector3Array() # Root-rotated local origin, reused by translation-only frames.
var part_posed: Array[Transform3D] = [] # bone * local from the last pose tick, reused by heading-only updates.
var buffers: Array[PackedFloat32Array] = []
var batches: Array[MultiMesh] = []
var mesh_bank: Array = []
var lod: int = -1
var forced_lod: int = -1
var pose_updates: int = 0
var total_pose_updates: int = 0
var full_updates: int = 0
var translated: int = 0
var submission_usec: int = 0
var pose_usec: int = 0
var prepare_usec: int = 0
var upload_usec: int = 0
var part_count: int = 0
var hidden_parts: int = 0

func configure(types: PackedInt32Array, styles: PackedInt32Array) -> void:
	assert(types.size() == styles.size())
	archetypes = types.duplicate(); variants = styles.duplicate()
	visual.configure(types.size())
	total_pose_updates = 0
	scales.resize(types.size()); clocks.resize(types.size())
	written_positions.resize(types.size()); written_headings.resize(types.size())
	bone_cache.clear(); current_pose.clear()
	for i in range(types.size()):
		scales[i] = .96 + float(styles[i] % 5) * .02
		var bones: Array[Transform3D] = []
		bones.resize(Poses.BONES); bones.fill(Transform3D.IDENTITY)
		bone_cache.append(bones)
		current_pose.append(bones)
	if batches.is_empty():
		create_shared_meshes()
		for shape in range(3):
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_colors = true
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = multi
			instance.name = ["ClothingPanels","RoundedParts","LimbSegments"][shape]
			add_child(instance)
			batches.append(multi)
			buffers.append(PackedFloat32Array())
	rebuild(0)

func create_shared_meshes() -> void:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = .86
	for level in range(3):
		var box := BoxMesh.new(); box.size = Vector3.ONE; box.material = material
		var round_mesh := SphereMesh.new()
		round_mesh.radius = .5; round_mesh.height = 1.0
		round_mesh.radial_segments = [16,10,6][level]
		round_mesh.rings = [8,5,3][level]; round_mesh.material = material
		var limb := CapsuleMesh.new()
		limb.radius = .5; limb.height = 2.0
		limb.radial_segments = [12,8,6][level]; limb.rings = [4,2,1][level]
		limb.material = material
		mesh_bank.append([box,round_mesh,limb])

## A part entirely inside an opaque box on the same bone is never visible; it is not drawn.
static func is_hidden(part: Dictionary, siblings: Array[Dictionary]) -> bool:
	var half: Vector3 = part.local.basis.get_scale() * .5
	for other: Dictionary in siblings:
		if is_same(other, part) or other.shape != 0 or other.bone != part.bone:
			continue
		var limit: Vector3 = other.local.basis.get_scale() * .5
		var gap: Vector3 = (part.local.origin - other.local.origin).abs() + half
		if gap.x <= limit.x and gap.y <= limit.y and gap.z <= limit.z:
			return true
	return false

func rebuild(level: int) -> void:
	lod = level
	var sizes := PackedInt32Array([0,0,0])
	var colors: Array[Color] = []
	part_start.resize(visual.count + 1)
	part_shape.clear(); part_slot.clear(); part_bone.clear(); part_local.clear()
	hidden_parts = 0
	for i in range(visual.count):
		part_start[i] = part_shape.size()
		var parts := Catalog.parts(archetypes[i],variants[i])
		for part: Dictionary in parts:
			if part.lod < level:
				continue
			if is_hidden(part,parts):
				hidden_parts += 1
				continue
			var local: Transform3D = part.local
			# CapsuleMesh's unit height is two; the catalog specifies full height.
			if part.shape == 2:
				local = local * Transform3D(Basis.IDENTITY.scaled_local(Vector3(1,.5,1)),Vector3.ZERO)
			part_shape.append(part.shape); part_slot.append(sizes[part.shape])
			part_bone.append(part.bone); part_local.append(local)
			colors.append(part.color.srgb_to_linear())
			sizes[part.shape] += 1
	part_start[visual.count] = part_shape.size()
	part_count = part_shape.size()
	part_origin.resize(part_count)
	part_posed.resize(part_count)
	for shape in range(3):
		batches[shape].mesh = mesh_bank[level][shape]
		batches[shape].instance_count = sizes[shape]
		buffers[shape].resize(sizes[shape] * STRIDE)
		buffers[shape].fill(0.0)
	for p in range(part_count):
		var k := part_slot[p] * STRIDE + 12
		var color := colors[p]
		var buffer := buffers[part_shape[p]]
		buffer[k] = color.r; buffer[k + 1] = color.g; buffer[k + 2] = color.b; buffer[k + 3] = color.a
	# Force a full update for everyone, then spread later pose ticks evenly over one period.
	var period: float = 1.0 / POSE_HZ[level]
	for i in range(visual.count):
		clocks[i] = period + fposmod(float(i) * .618034, 1.0) * period
		written_positions[i] = Vector3.INF

func present_simulation(data: Data, alpha: float, delta: float, tick_delta: float, camera: Camera3D) -> void:
	Bridge.submit(visual,data,alpha,delta,tick_delta)
	present(delta,camera)

func present(delta: float, camera: Camera3D) -> void:
	var started := Time.get_ticks_usec()
	var height_pixels := 1.78 * camera.get_viewport().get_visible_rect().size.y / camera.size
	var next_lod := forced_lod if forced_lod >= 0 else (0 if height_pixels >= 42.0 else 1 if height_pixels >= 22.0 else 2)
	if next_lod != lod:
		rebuild(next_lod)
	pose_updates = 0; pose_usec = 0; full_updates = 0; translated = 0
	var hz: float = POSE_HZ[lod]
	var tolerance: float = HEADING_TOLERANCE[lod]
	for i in range(visual.count):
		clocks[i] += delta
		if clocks[i] + EPSILON >= 1.0 / hz or written_positions[i] == Vector3.INF:
			var pose_started := Time.get_ticks_usec()
			clocks[i] = maxf(0.0, clocks[i] - floor((clocks[i] + EPSILON) * hz) / hz)
			sample_pose(i)
			pose_updates += 1
			pose_usec += Time.get_ticks_usec() - pose_started
			write_full(i, true)
			full_updates += 1
		elif absf(wrapf(visual.headings[i] - written_headings[i], -PI, PI)) > tolerance:
			write_full(i, false)
			full_updates += 1
		elif visual.positions[i] != written_positions[i]:
			write_origins(i)
			translated += 1
	total_pose_updates += pose_updates
	var upload_started := Time.get_ticks_usec()
	if full_updates + translated > 0:
		for shape in range(3):
			RenderingServer.multimesh_set_buffer(batches[shape].get_rid(),buffers[shape])
	upload_usec = Time.get_ticks_usec() - upload_started
	submission_usec = Time.get_ticks_usec() - started
	prepare_usec = submission_usec - upload_usec - pose_usec

func sample_pose(i: int) -> void:
	var state: int = visual.states[i]
	var phase: float = visual.phases[i]
	# LOD 2 always, LOD 1 outside state transitions: nearest shared key frame (1/32 cycle),
	# no per-bone interpolation. LOD 2 shows the dominant state during blends.
	if lod == 2 or (lod == 1 and visual.blends[i] >= 1.0):
		if visual.blends[i] < .5:
			state = visual.previous_states[i]; phase = visual.previous_phases[i]
		var frame := mini(int(phase * (Poses.STEPS - 1) + .5), Poses.STEPS - 1) if state == Poses.State.STOP else int(fposmod(phase, 1.0) * Poses.STEPS + .5) % Poses.STEPS
		current_pose[i] = poses.bank[state][frame]
		return
	var bones: Array = bone_cache[i]
	for bone in range(Poses.BONES):
		var current := poses.sample(state,phase,bone)
		if visual.blends[i] < 1.0:
			current = poses.sample(visual.previous_states[i],visual.previous_phases[i],bone).interpolate_with(current,visual.blends[i])
		bones[bone] = current
	current_pose[i] = bones

## Rewrites all 12 transform floats; repose=false reuses bone * local from the last pose tick.
func write_full(i: int, repose: bool) -> void:
	var position := visual.positions[i]
	var root := Basis(Vector3.UP,visual.headings[i]).scaled_local(Vector3.ONE*scales[i])
	var bones: Array = current_pose[i]
	for p in range(part_start[i], part_start[i + 1]):
		var x: Transform3D
		if repose:
			var bone: Transform3D = bones[part_bone[p]]
			x = bone * part_local[p]
			part_posed[p] = x
		else:
			x = part_posed[p]
		var b := root * x.basis
		var o := root * x.origin
		part_origin[p] = o
		o += position
		var buffer := buffers[part_shape[p]]
		var k := part_slot[p] * STRIDE
		buffer[k] = b.x.x; buffer[k + 1] = b.y.x; buffer[k + 2] = b.z.x; buffer[k + 3] = o.x
		buffer[k + 4] = b.x.y; buffer[k + 5] = b.y.y; buffer[k + 6] = b.z.y; buffer[k + 7] = o.y
		buffer[k + 8] = b.x.z; buffer[k + 9] = b.y.z; buffer[k + 10] = b.z.z; buffer[k + 11] = o.z
	written_positions[i] = position
	written_headings[i] = visual.headings[i]

func write_origins(i: int) -> void:
	var position := visual.positions[i]
	for p in range(part_start[i], part_start[i + 1]):
		var o := part_origin[p] + position
		var buffer := buffers[part_shape[p]]
		var k := part_slot[p] * STRIDE
		buffer[k + 3] = o.x; buffer[k + 7] = o.y; buffer[k + 11] = o.z
	written_positions[i] = position

func get_character_probe(index: int) -> Dictionary:
	assert(index >= 0 and index < visual.count)
	var limb := Transform3D.IDENTITY
	for p in range(part_start[index], part_start[index + 1]):
		if part_bone[p] == 4:
			limb = batches[part_shape[p]].get_instance_transform(part_slot[p])
			break
	var bones: Array = current_pose[index]
	return {"state":Poses.NAMES[visual.states[index]],"phase":visual.phases[index],"position":visual.positions[index],
		"heading":visual.headings[index],"thigh":bones[4],"foot":bones[12],"rendered_thigh":limb}

func get_render_state() -> Dictionary:
	var hist := [0,0,0,0,0]
	for state in visual.states:
		hist[state] += 1
	var first := batches[2].get_instance_transform(0) if not batches.is_empty() and batches[2].instance_count > 0 else Transform3D.IDENTITY
	return {"count":visual.count,"lod":lod,"parts":part_count,"hidden_parts":hidden_parts,"batches":batches.size(),"character_nodes":0,
		"states":hist,"transitions":Array(visual.transitions),"pose_updates":pose_updates,"total_pose_updates":total_pose_updates,"pose_usec":pose_usec,
		"full_updates":full_updates,"translated":translated,"prepare_usec":prepare_usec,"upload_usec":upload_usec,
		"submission_usec":submission_usec,"first_limb":first,"positions":Array(visual.positions),"phases":Array(visual.phases)}
