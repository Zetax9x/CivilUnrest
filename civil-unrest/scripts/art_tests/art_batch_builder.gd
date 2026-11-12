extends Node3D
## Static geometry is uploaded once. Subclasses own original modules, not simulation data.
const MATERIAL_DIR := "res://assets/art_direction/materials/"
var batches: Dictionary = {}
var mesh_library: Dictionary = {}
var part_count: int = 0

func piece(material: String, point: Vector3, size: Vector3, shape: String = "box", angles: Vector3 = Vector3.ZERO) -> void:
	var key := material + "/" + shape
	if not batches.has(key):
		batches[key] = []
	var basis := Basis.from_euler(angles).scaled_local(size)
	batches[key].append(Transform3D(basis, point))
	part_count += 1

func beam(material: String, start: Vector3, finish: Vector3, diameter: float) -> void:
	var direction := finish - start
	var basis := Basis.IDENTITY
	if absf(direction.normalized().dot(Vector3.UP)) < 0.999:
		basis = Basis.looking_at(direction.normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI / 2.0)
	piece_transform(material, "cylinder", Transform3D(basis.scaled_local(Vector3(diameter, direction.length(), diameter)), (start + finish) * 0.5))

func piece_transform(material: String, shape: String, transform: Transform3D) -> void:
	var key := material + "/" + shape
	if not batches.has(key):
		batches[key] = []
	batches[key].append(transform)
	part_count += 1

func label_text(text: String, point: Vector3, height: float, color: Color, yaw: float = 0.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = height / 64.0
	label.modulate = color
	label.outline_size = 0
	label.position = point
	label.rotation.y = yaw
	add_child(label)

func mesh_for(shape: String) -> Mesh:
	if mesh_library.has(shape):
		return mesh_library[shape]
	var mesh: PrimitiveMesh
	match shape:
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 12
			mesh = cylinder
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 16
			sphere.rings = 8
			mesh = sphere
		_:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			mesh = box
	mesh_library[shape] = mesh
	return mesh

func flush() -> void:
	for key: String in batches:
		var names := key.split("/")
		var transforms: Array = batches[key]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh_for(names[1])
		multi.instance_count = transforms.size()
		for i in range(transforms.size()):
			multi.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = names[0] + "_" + names[1]
		instance.multimesh = multi
		instance.material_override = load(MATERIAL_DIR + names[0] + ".tres")
		add_child(instance)
	batches.clear()

## Convex X/Y profile extruded along Z; flat normals preserve designed body panels.
func prism(shape: String, profile: PackedVector2Array, depth: float) -> void:
	var area: float = 0.0
	for i in range(profile.size()):
		var next := (i + 1) % profile.size()
		area += profile[i].cross(profile[next])
	if area < 0.0:
		profile.reverse()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for side in [-1.0, 1.0]:
		for i in range(1, profile.size() - 1):
			var a := Vector3(profile[0].x, profile[0].y, side * depth * 0.5)
			var b := Vector3(profile[i].x, profile[i].y, side * depth * 0.5)
			var c := Vector3(profile[i + 1].x, profile[i + 1].y, side * depth * 0.5)
			triangle(vertices, normals, a, b if side < 0 else c, c if side < 0 else b)
	for i in range(profile.size()):
		var next := (i + 1) % profile.size()
		var a := Vector3(profile[i].x, profile[i].y, -depth * 0.5)
		var b := Vector3(profile[next].x, profile[next].y, -depth * 0.5)
		var c := Vector3(profile[next].x, profile[next].y, depth * 0.5)
		var d := Vector3(profile[i].x, profile[i].y, depth * 0.5)
		triangle(vertices, normals, a, c, b)
		triangle(vertices, normals, a, d, c)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_library[shape] = mesh

func triangle(vertices: PackedVector3Array, normals: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	vertices.append_array(PackedVector3Array([a, b, c]))
	normals.append_array(PackedVector3Array([normal, normal, normal]))
