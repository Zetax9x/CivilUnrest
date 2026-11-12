extends Node3D
## Centralized renderer: three MultiMesh batches, zero per-character nodes.
const Catalog = preload("res://scripts/characters/character_catalog.gd")
const Poses = preload("res://scripts/characters/character_pose_library.gd")
const Visual = preload("res://scripts/characters/character_visual_state.gd")
const Bridge = preload("res://scripts/characters/character_simulation_adapter.gd")
const Data = preload("res://scripts/simulation/crowd_state.gd")
var visual := Visual.new()
var poses := Poses.new()
var archetypes := PackedInt32Array()
var variants := PackedInt32Array()
var scales := PackedFloat32Array()
var bindings: Array = []
var bone_cache: Array = []
var clocks := PackedFloat32Array()
var batches: Array[MultiMesh] = []
var mesh_bank: Array = []
var lod: int = -1
var forced_lod: int = -1
var pose_updates: int = 0
var total_pose_updates: int = 0
var submission_usec: int = 0
var pose_usec: int = 0
var part_count: int = 0

func configure(types: PackedInt32Array, styles: PackedInt32Array) -> void:
	assert(types.size() == styles.size())
	archetypes = types.duplicate(); variants = styles.duplicate()
	visual.configure(types.size())
	total_pose_updates = 0
	scales.resize(types.size()); clocks.resize(types.size())
	bone_cache.clear()
	for i in range(types.size()):
		scales[i] = .96 + float(styles[i] % 5) * .02
		var bones: Array[Transform3D] = []
		bones.resize(Poses.BONES); bones.fill(Transform3D.IDENTITY)
		bone_cache.append(bones)
		clocks[i] = 1.0
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

func rebuild(level: int) -> void:
	lod = level; bindings.clear()
	var sizes := PackedInt32Array([0,0,0])
	for i in range(visual.count):
		var selected: Array[Dictionary] = []
		for part: Dictionary in Catalog.parts(archetypes[i],variants[i]):
			if part.lod < level:
				continue
			var binding: Dictionary = part.duplicate()
			binding.slot = sizes[part.shape]
			# CapsuleMesh's unit height is two; the catalog specifies full height.
			if part.shape == 2:
				binding.local = part.local * Transform3D(Basis.IDENTITY.scaled_local(Vector3(1,.5,1)),Vector3.ZERO)
			sizes[part.shape] += 1
			selected.append(binding)
		bindings.append(selected)
	for shape in range(3):
		batches[shape].mesh = mesh_bank[level][shape]
		batches[shape].instance_count = sizes[shape]
	part_count = sizes[0] + sizes[1] + sizes[2]
	for i in range(visual.count):
		clocks[i] = 1.0
		for binding: Dictionary in bindings[i]:
			batches[binding.shape].set_instance_color(binding.slot,binding.color.srgb_to_linear())

func present_simulation(data: Data, alpha: float, delta: float, tick_delta: float, camera: Camera3D) -> void:
	Bridge.submit(visual,data,alpha,delta,tick_delta)
	present(delta,camera)

func present(delta: float, camera: Camera3D) -> void:
	var started := Time.get_ticks_usec()
	var height_pixels := 1.78 * camera.get_viewport().get_visible_rect().size.y / camera.size
	var next_lod := forced_lod if forced_lod >= 0 else (0 if height_pixels >= 42.0 else 1 if height_pixels >= 22.0 else 2)
	if next_lod != lod:
		rebuild(next_lod)
	pose_updates = 0; pose_usec = 0
	for i in range(visual.count):
		clocks[i] += delta
		var hz: float = [60.0,30.0,10.0][lod]
		if clocks[i] + .00001 >= 1.0/hz:
			var pose_started := Time.get_ticks_usec()
			clocks[i] = maxf(0.0, clocks[i] - floor((clocks[i] + .00001)*hz)/hz)
			for bone in range(Poses.BONES):
				var current := poses.sample(visual.states[i],visual.phases[i],bone)
				if visual.blends[i] < 1.0:
					current = poses.sample(visual.previous_states[i],visual.previous_phases[i],bone).interpolate_with(current,visual.blends[i])
				bone_cache[i][bone] = current
			pose_updates += 1
			total_pose_updates += 1
			pose_usec += Time.get_ticks_usec() - pose_started
		var root := Transform3D(Basis(Vector3.UP,visual.headings[i]).scaled_local(Vector3.ONE*scales[i]),visual.positions[i])
		for binding: Dictionary in bindings[i]:
			var bone: Transform3D = bone_cache[i][binding.bone]
			batches[binding.shape].set_instance_transform(binding.slot,root*bone*binding.local)
	submission_usec = Time.get_ticks_usec() - started

func get_character_probe(index: int) -> Dictionary:
	assert(index >= 0 and index < visual.count)
	var limb := Transform3D.IDENTITY
	for binding: Dictionary in bindings[index]:
		if binding.bone == 4:
			limb = batches[binding.shape].get_instance_transform(binding.slot)
			break
	return {"state":Poses.NAMES[visual.states[index]],"phase":visual.phases[index],"position":visual.positions[index],
		"heading":visual.headings[index],"thigh":bone_cache[index][4],"foot":bone_cache[index][12],"rendered_thigh":limb}

func get_render_state() -> Dictionary:
	var hist := [0,0,0,0,0]
	for state in visual.states:
		hist[state] += 1
	var first := batches[2].get_instance_transform(0) if not batches.is_empty() else Transform3D.IDENTITY
	return {"count":visual.count,"lod":lod,"parts":part_count,"batches":batches.size(),"character_nodes":0,
		"states":hist,"transitions":Array(visual.transitions),"pose_updates":pose_updates,"total_pose_updates":total_pose_updates,"pose_usec":pose_usec,
		"submission_usec":submission_usec,"first_limb":first,"positions":Array(visual.positions),"phases":Array(visual.phases)}
