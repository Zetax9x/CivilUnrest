extends "res://scripts/art_tests/art_batch_builder.gd"
## Visual footprints exactly mirror existing 2D obstacles. No independent physics.
func configure(obstacles: Array[Rect2]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for rect in obstacles:
		var point := (rect.get_center() - Vector2(800,450))*.05
		piece("limestone",Vector3(point.x,.72,point.y),Vector3(rect.size.x*.05,1.1,rect.size.y*.05))
		piece("iron",Vector3(point.x,1.30,point.y),Vector3(rect.size.x*.05+.04,.08,rect.size.y*.05))
	flush()
