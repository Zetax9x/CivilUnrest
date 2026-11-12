extends Node3D
## Original procedural geometry. Static primitives are grouped by material/shape.
## All solid street furniture and building footprints lie outside the 2D walk domain.
var transforms: Dictionary = {}
var colors: Dictionary = {}
var batches: int = 0
var primitive_count: int = 0
const WALK_DOMAIN := Rect2(-40, -22.5, 80, 45)
var solid_footprints: Array[Rect2] = []

func _ready() -> void:
	build()

func _piece(kind: String, size: Vector3, at: Vector3, tint: Color, yaw: float = 0.0) -> void:
	if not transforms.has(kind):
		transforms[kind] = []
		colors[kind] = []
	transforms[kind].append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(size), at))
	colors[kind].append(tint)
	primitive_count += 1

func _box(size: Vector3, at: Vector3, tint: String, yaw: float = 0.0, kind: String = "stone") -> void:
	_piece(kind, size, at, Color(tint), yaw)

func _solid(center: Vector2, size: Vector2) -> void:
	var footprint := Rect2(center - size * 0.5, size)
	assert(not footprint.intersects(WALK_DOMAIN.grow(0.4)), "Decoration intersects crowd domain")
	solid_footprints.append(footprint)

func build() -> void:
	_ground()
	_building(Vector3(-23, 0, -33), Vector3(27, 12, 16), "#b9ad91", 3, "CORTILE 09")
	_building(Vector3(10, 0, -34), Vector3(25, 16, 18), "#b1846b", 4, "GALLERIA")
	_building(Vector3(48, 0, -8), Vector3(12, 10, 30), "#87918c", 2, "OFFICINA")
	for x in [-44.0, -25.0, -5.0, 17.0, 38.0]:
		_lamp(Vector3(x, 0, 26))
	for x in [-45.0, -6.0, 24.0]:
		_tree(Vector3(x, 0, 30))
		_bench(Vector3(x + 4, 0, 26))
	_car(Vector3(-26, 0, 29.5), "#995d4d", false)
	_car(Vector3(1, 0, 29.5), "#d1cec1", false)
	_car(Vector3(32, 0, 29.5), "#4d646d", false)
	_car(Vector3(-44, 0, -14), "#e4e8e6", true, PI * 0.5)
	# North-edge bike racks, bollards and planting beds.
	for x in range(-39, 39, 4):
		_box(Vector3(0.17, 0.85, 0.17), Vector3(x, 0.6, -23.5), "#465657", 0, "metal")
	for x in [-38.0, 32.0]:
		_box(Vector3(5, 0.6, 1.1), Vector3(x, 0.45, -23.7), "#8b8c7c")
		_box(Vector3(4.7, 0.32, 0.85), Vector3(x, 0.9, -23.7), "#5e7056", 0, "foliage")
		_solid(Vector2(x, -23.7), Vector2(5, 1.1))
	_sign("PIAZZA DEL TIGLIO", Vector3(-27, 1.3, -24.55), 0.038)
	_flush()

func _ground() -> void:
	_box(Vector3(120, 0.8, 96), Vector3(0, -0.42, 0), "#686d65")
	_box(Vector3(116, 0.12, 15), Vector3(0, 0.0, 0), "#373e43", 0, "asphalt")
	for side in [-1.0, 1.0]:
		_box(Vector3(116, 0.18, 22), Vector3(0, 0.09, side * 18.6), "#aaa99b")
		# Pavement joints: sparse, opaque, static instancing rather than coplanar textures.
		for x in range(-56, 57, 2):
			_box(Vector3(0.025, 0.008, 21.8), Vector3(x, 0.184, side * 18.6), "#93978e")
		for row in range(8, 30, 2):
			_box(Vector3(116, 0.008, 0.025), Vector3(0, 0.184, side * row), "#93978e")
		# A low edge curb; openings at the zebra crossing provide visual ramps.
		for x in [-30.0, 30.0]:
			_box(Vector3(47, 0.16, 0.32), Vector3(x, 0.08, side * 7.6), "#d0cfc0")
		_box(Vector3(102, 0.025, 0.1), Vector3(0, 0.075, side * 6.7), "#d9d6bd", 0, "paint")
	for x in range(-54, 55, 7):
		_box(Vector3(3.4, 0.012, 0.14), Vector3(x, 0.075, 0), "#e0dbc2", 0, "paint")
	for z in range(-6, 7, 2):
		_box(Vector3(6, 0.013, 0.85), Vector3(-5, 0.077, z), "#e5e0c9", 0, "paint")
	# Parking bays and a darker paved margin, all outside the walking domain.
	_box(Vector3(104, 0.018, 5.8), Vector3(0, 0.19, 29.5), "#858d89")
	for x in range(-49, 50, 9):
		_box(Vector3(0.08, 0.012, 5.6), Vector3(x, 0.207, 29.5), "#d6d4bf", 0, "paint")
	# Subtle original asphalt aggregate; grouped inexpensive small dark fragments.
	for i in range(260):
		var x := float((i * 137) % 1120) * 0.1 - 56.0
		var z := float((i * 53) % 140) * 0.1 - 7.0
		_box(Vector3(0.09, 0.005, 0.045), Vector3(x, 0.065, z), "#42484b", 0, "asphalt")

func _building(at: Vector3, size: Vector3, wall: String, floors: int, title: String) -> void:
	_solid(Vector2(at.x, at.z), Vector2(size.x, size.z))
	_box(size, at + Vector3(0, size.y * 0.5 + 0.18, 0), wall)
	_box(Vector3(size.x + 0.4, 0.65, size.z + 0.4), at + Vector3(0, 0.5, 0), "#7c817b")
	for floor_index in range(floors + 1):
		var y := 0.7 + floor_index * 3.5
		_box(Vector3(size.x + 0.3, 0.18, size.z + 0.3), at + Vector3(0, y, 0), "#d2c7af")
	# Windows, stone lintels and deep opaque recesses on all four sides.
	for face in range(4):
		var front := face % 2 == 0
		var span := size.x if front else size.z
		var columns := floori(span / 3.4)
		for column in range(columns):
			var horizontal := (float(column) + 0.5) * span / columns - span * 0.5
			for floor_index in range(floors):
				var y := 2.0 + floor_index * 3.5
				var sign_value := 1.0 if face < 2 else -1.0
				var local := Vector3(horizontal, y, sign_value * (size.z * 0.5 + 0.035)) if front else Vector3(sign_value * (size.x * 0.5 + 0.035), y, horizontal)
				var window_size := Vector3(1.45, 1.95, 0.11) if front else Vector3(0.11, 1.95, 1.45)
				_box(window_size * Vector3(1.17, 1.1, 1.17), at + local, "#c4baa4")
				var normal := Vector3(0, 0, sign_value) if front else Vector3(sign_value, 0, 0)
				_box(window_size, at + local + normal * 0.09, "#364d58", 0, "glass")
				var sill := Vector3(1.85, 0.14, 0.48) if front else Vector3(0.48, 0.14, 1.85)
				_box(sill, at + local + Vector3(0, -1.0, 0), "#d8cfba")
	# Layered roof/parapet, rooftop equipment and corner pilasters.
	_box(Vector3(size.x + 0.8, 0.35, size.z + 0.8), at + Vector3(0, size.y + 0.35, 0), "#d4c9b2")
	_box(Vector3(size.x - 0.5, 0.25, size.z - 0.5), at + Vector3(0, size.y + 0.63, 0), "#4d5b5b", 0, "metal")
	for side in [-1.0, 1.0]:
		_box(Vector3(size.x + 0.8, 0.5, 0.28), at + Vector3(0, size.y + 0.65, side * size.z * 0.5), "#c3b9a2")
		_box(Vector3(0.28, 0.5, size.z), at + Vector3(side * size.x * 0.5, size.y + 0.65, 0), "#c3b9a2")
		_box(Vector3(0.45, size.y, 0.55), at + Vector3(side * (size.x * 0.5 - 0.15), size.y * 0.5, size.z * 0.5), "#d3c8b1")
	for i in range(2):
		_box(Vector3(1.4, 1.8, 1.1), at + Vector3(-4 + i * 7, size.y + 1.4, -1), "#857d70")
		_box(Vector3(1.7, 0.17, 1.4), at + Vector3(-4 + i * 7, size.y + 2.32, -1), "#4d5654")
	# Street-level recessed shopfront, canopy, door and original generic sign.
	_box(Vector3(5.8, 2.6, 0.22), at + Vector3(0, 1.5, size.z * 0.5 + 0.15), "#294247", 0, "glass")
	_box(Vector3(6.8, 0.28, 1.1), at + Vector3(0, 3.1, size.z * 0.5 + 0.5), "#405b55")
	_sign(title, at + Vector3(0, 3.8, size.z * 0.5 + 0.3), 0.04)

func _lamp(at: Vector3) -> void:
	_solid(Vector2(at.x, at.z), Vector2(0.6, 0.6))
	_piece("cylinder", Vector3(0.16, 5.4, 0.16), at + Vector3(0, 2.9, 0), Color("#3c4b4c"))
	_box(Vector3(0.55, 0.25, 0.55), at + Vector3(0, 0.3, 0), "#52605d")
	_box(Vector3(1.6, 0.12, 0.16), at + Vector3(-0.65, 5.6, 0), "#38494a", 0, "metal")
	_box(Vector3(0.8, 0.16, 0.5), at + Vector3(-1.3, 5.52, 0), "#e7d7aa", 0, "lamp")

func _tree(at: Vector3) -> void:
	_solid(Vector2(at.x, at.z), Vector2(3, 3))
	_box(Vector3(3.3, 0.55, 3.3), at + Vector3(0, 0.4, 0), "#8b8e7c")
	_box(Vector3(2.9, 0.08, 2.9), at + Vector3(0, 0.72, 0), "#655f4a")
	_piece("cylinder", Vector3(0.35, 3.1, 0.35), at + Vector3(0, 2, 0), Color("#6c5b44"))
	for i in range(4):
		var offset := Vector3(sin(i * 2.1) * 0.8, 0.35 * (i % 2), cos(i * 2.1) * 0.8)
		_piece("leaf", Vector3(3.3, 3.4, 3.2), at + Vector3(0, 4.4, 0) + offset, Color("#637754") if i % 2 == 0 else Color("#768363"))

func _bench(at: Vector3) -> void:
	_solid(Vector2(at.x, at.z), Vector2(2.5, 0.8))
	for i in range(4):
		_box(Vector3(2.5, 0.08, 0.14), at + Vector3(0, 0.65, -0.25 + i * 0.17), "#82674b")
	for side in [-1.0, 1.0]:
		_box(Vector3(0.1, 0.5, 0.65), at + Vector3(side, 0.4, 0), "#3c4b4b", 0, "metal")
	_box(Vector3(2.5, 0.45, 0.12), at + Vector3(0, 0.97, 0.36), "#8f7354")

func _car(at: Vector3, paint: String, police: bool, yaw: float = 0.0) -> void:
	_solid(Vector2(at.x, at.z), Vector2(5.2, 5.2))
	var forward := Basis(Vector3.UP, yaw)
	var height := 0.2
	_box(Vector3(4.7 if police else 4.2, 0.7, 1.85), at + Vector3(0, height + 0.7, 0), paint, yaw, "car")
	_box(Vector3(2.6, 0.85 if police else 0.65, 1.68), at + Vector3(0, height + 1.35, 0), "#45616b", yaw, "glass")
	_box(Vector3(2.2, 0.12, 1.78), at + Vector3(0, height + 1.8, 0), paint, yaw, "car")
	for axle in [-1.4, 1.4]:
		for side in [-1.0, 1.0]:
			_piece("wheel", Vector3(0.65, 0.65, 0.65), at + forward * Vector3(axle, height + 0.35, side), Color("#293033"), yaw)
			_box(Vector3(0.3, 0.13, 0.045), at + forward * Vector3(2.1, height + 0.8, side * 0.65), "#e9dfbb", yaw, "lamp")
	if police:
		_box(Vector3(3.7, 0.24, 1.88), at + Vector3(0, height + 0.75, 0), "#2c5f8a", yaw, "car")
		_box(Vector3(1.3, 0.18, 0.35), at + Vector3(0, height + 1.98, 0), "#378fca", yaw, "lamp")
		_sign("POLIZIA", at + Vector3(0, height + 1.15, 1.1), 0.025)

func _sign(text: String, at: Vector3, pixel_size: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.pixel_size = pixel_size
	label.font_size = 32
	label.outline_size = 3
	label.modulate = Color("#f0ead8")
	label.no_depth_test = false
	add_child(label)

func _flush() -> void:
	for kind: String in transforms:
		var mesh: Mesh
		if kind == "cylinder" or kind == "wheel":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 10
			if kind == "wheel":
				# Wheel axle along local Z rather than Y.
				mesh = cylinder
			else:
				mesh = cylinder
		elif kind == "leaf":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 10
			sphere.rings = 5
			mesh = sphere
		else:
			mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.9
		if kind == "glass" or kind == "car" or kind == "metal":
			material.roughness = 0.32 if kind == "glass" else 0.55
			material.metallic = 0.25
		if kind == "lamp":
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material = material
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.mesh = mesh
		batch.instance_count = transforms[kind].size()
		for i in range(batch.instance_count):
			var transform_value: Transform3D = transforms[kind][i]
			if kind == "wheel":
				transform_value.basis = Basis(Vector3.UP, 0) * transform_value.basis * Basis(Vector3.RIGHT, PI * 0.5)
			batch.set_instance_transform(i, transform_value)
			var tint: Color = colors[kind][i]
			batch.set_instance_color(i, tint.srgb_to_linear())
		var instance := MultiMeshInstance3D.new()
		instance.name = kind.to_pascal_case() + "Batch"
		instance.multimesh = batch
		if kind == "paint" or kind == "asphalt":
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		batches += 1
	transforms.clear()
	colors.clear()
