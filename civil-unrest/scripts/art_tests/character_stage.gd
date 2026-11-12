extends "res://scripts/art_tests/art_batch_builder.gd"
## Small original neutral stage; reuses ItalianStreet materials, not its scene.
func _ready() -> void:
	piece("dark_stone",Vector3(0,-.17,0),Vector3(22,.3,18))
	piece("paving",Vector3(0,-.025,0),Vector3(21.5,.05,17.5))
	for x in range(5):
		for row in range(4):
			var center := Vector3((x-2)*3.5,0,(row-1.5)*3.6)
			piece("limestone",center+Vector3(0,.006,0),Vector3(2.85,.012,3.15))
			piece("shutters" if row == 0 else "terracotta" if row == 1 else "police_blue",center+Vector3(0,.016,1.45),Vector3(2.7,.01,.09))
	for col in range(5):
		label_text(["IDLE","WALK","RUN","TURN","STOP"][col],Vector3((col-2)*3.5,.24,-8.0),.35,Color("#343e3a"))
	for row in range(4):
		label_text(["CIVILI","MANIFESTANTI","POLIZIA","VARIANTI"][row],Vector3(-10.0,.20,(row-1.5)*3.6),.25,Color("#343e3a"),PI/2.0)
	flush()
