extends Node3D
## Five shared batches, no per-agent nodes, physics or animation callbacks.
## Future animated/LOD renderer can replace this module at the same present() boundary.
const Adapter = preload("res://scripts/rendering/crowd_3d_adapter.gd")
const State = preload("res://scripts/simulation/crowd_state.gd")
var bodies: MultiMesh
var heads: MultiMesh
var legs: MultiMesh
var faces: MultiMesh
var shadows: MultiMesh
var headings := PackedFloat32Array()
var submission_usec: int = 0
var state: State

func _batch(mesh: Mesh, tint: Color, use_colors: bool = false, unshaded: bool = false) -> MultiMesh:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.85
	material.vertex_color_use_as_albedo = use_colors
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = use_colors
	batch.mesh = mesh
	batch.custom_aabb = AABB(Vector3(-42, -1, -25), Vector3(84, 5, 50))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = batch
	# Contact discs provide cheap grounding; avoid five extra crowd shadow passes.
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return batch

func configure(data: State) -> void:
	state = data
	if bodies == null:
		var torso := CapsuleMesh.new()
		torso.radius = 0.205
		torso.height = 0.76
		torso.radial_segments = 8
		torso.rings = 2
		bodies = _batch(torso, Color.WHITE, true)
		var skull := SphereMesh.new()
		skull.radius = 0.145
		skull.height = 0.29
		skull.radial_segments = 8
		skull.rings = 4
		heads = _batch(skull, Color("#c49b7b"))
		var trousers := BoxMesh.new()
		trousers.size = Vector3(0.31, 0.55, 0.24)
		legs = _batch(trousers, Color("#26313d"))
		var face := BoxMesh.new()
		face.size = Vector3(0.16, 0.12, 0.035)
		faces = _batch(face, Color("#e9c6a4"))
		var disc := CylinderMesh.new()
		disc.top_radius = 0.245
		disc.bottom_radius = 0.245
		disc.height = 0.008
		disc.radial_segments = 12
		shadows = _batch(disc, Color("#555851"), false, true)
	for batch: MultiMesh in [bodies, heads, legs, faces, shadows]:
		batch.instance_count = data.count
	headings.resize(data.count)
	headings.fill(0.0)
	var palette: Array[Color] = [Color("#456d78"), Color("#bc8050"), Color("#69725a"), Color("#b6ada0"), Color("#3c4858"), Color("#875959")]
	for i in range(data.count):
		bodies.set_instance_color(i, palette[i % palette.size()].srgb_to_linear())
	present(1.0)

func present(alpha: float) -> void:
	if state == null:
		return
	var started := Time.get_ticks_usec()
	for i in range(state.count):
		var point := state.previous[i].lerp(state.positions[i], clampf(alpha, 0.0, 1.0))
		var origin := Adapter.to_world(point)
		headings[i] = Adapter.heading(state.previous[i], state.positions[i], headings[i])
		var basis := Basis(Vector3.UP, headings[i])
		bodies.set_instance_transform(i, Transform3D(basis, origin + Vector3(0, 0.95, 0)))
		heads.set_instance_transform(i, Transform3D(basis, origin + Vector3(0, 1.48, 0)))
		legs.set_instance_transform(i, Transform3D(basis, origin + Vector3(0, 0.29, 0)))
		faces.set_instance_transform(i, Transform3D(basis, origin + Vector3(0, 1.49, 0) + basis * Vector3(0, 0, -0.143)))
		shadows.set_instance_transform(i, Transform3D(Basis.IDENTITY, origin + Vector3(0, 0.009, 0)))
	submission_usec = Time.get_ticks_usec() - started

func get_render_state() -> Dictionary:
	var first := bodies.get_instance_transform(0) if bodies != null else Transform3D.IDENTITY
	return {"instances": state.count if state != null else 0, "batches": 5, "first_origin": first.origin, "first_heading": headings[0] if not headings.is_empty() else 0.0, "submission_usec": submission_usec}
