extends Node3D
## Scripted presentation trajectories only; never writes to the gameplay simulation.
@export_range(10,20,10) var character_count: int = 20
const Catalog = preload("res://scripts/characters/character_catalog.gd")
@onready var renderer: Node3D = $Characters
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var status: Label = $UI/Status
var elapsed: float = 0.0
var paused: bool = false
var updates: int = 0
var cpu_total_usec: int = 0
var cpu_max_usec: int = 0
var frame_count: int = 0

func _ready() -> void:
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	set_population(character_count)

func set_population(size: int) -> void:
	assert(size == 10 or size == 20)
	character_count = size; elapsed = 0.0; paused = false
	updates = 0; cpu_total_usec = 0; cpu_max_usec = 0; frame_count = 0
	var types := PackedInt32Array()
	var styles := PackedInt32Array()
	for i in range(size):
		var slot: int = i if size == 20 else i*2
		types.append((slot/5) % 3)
		styles.append(slot % 5 + slot/5)
	renderer.configure(types,styles)
	update_demo(1.0/60.0)
	renderer.present(1.0/60.0,camera)

func update_demo(delta: float) -> void:
	for i in range(character_count):
		var slot: int = i if character_count == 20 else i*2
		var column := slot % 5
		var row: int = slot/5
		var point := Vector3((column-2)*3.5,0,(row-1.5)*3.6)
		var velocity := Vector3.ZERO
		var heading := PI
		if column == 1 or column == 2:
			# Bounded, isolated lanes. Reversals exercise heading smoothing.
			var speed := 1.0 if column == 1 else 2.5
			var travel := fposmod(elapsed*speed + row*.2,4.8)
			var direction := -1.0 if travel < 2.4 else 1.0
			point.z += 1.2 - travel if travel < 2.4 else travel - 3.6
			velocity.z = speed*direction
			heading = 0.0 if direction < 0 else PI
		elif column == 3:
			heading = floor(elapsed/1.5) * PI/2.0
		elif column == 4:
			var cycle := fposmod(elapsed,8.0)
			if cycle < 4.0:
				heading = 0.0
				point.z += .75-minf(cycle,1.5)
				velocity.z = -1.0 if cycle < 1.5 else 0.0
			else:
				point.z += -.75+minf(cycle-4.0,1.5)
				velocity.z = 1.0 if cycle < 5.5 else 0.0
				heading = PI
		renderer.visual.submit(i,point,velocity,heading,delta)
	updates += 1

func _process(delta: float) -> void:
	if not paused:
		elapsed += delta
		update_demo(delta)
	var began := Time.get_ticks_usec()
	renderer.present(delta,camera)
	var cost := Time.get_ticks_usec()-began
	cpu_total_usec += cost; cpu_max_usec = maxi(cpu_max_usec,cost); frame_count += 1
	if frame_count % 15 == 0:
		status.text = "PERSONAGGI 3D  |  %d unità  |  %d FPS  |  LOD %d\n1: 10   2: 20   SPAZIO: pausa   R: ripristina   WASD / rotella / Q E / HOME" % [character_count,Engine.get_frames_per_second(),renderer.lod]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: set_population(10)
			KEY_2: set_population(20)
			KEY_SPACE: paused = not paused
			KEY_R: set_population(character_count)

func get_showcase_state() -> Dictionary:
	return {"elapsed":elapsed,"paused":paused,"demo_updates":updates,"frames_presented":frame_count,
		"renderer_cpu_mean_usec":float(cpu_total_usec)/maxi(frame_count,1),
		"renderer_cpu_max_usec":cpu_max_usec,"render":renderer.get_render_state()}
