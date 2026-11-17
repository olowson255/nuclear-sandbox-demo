class_name Molecule
extends RefCounted

var pixel_color: Color = Color.BLUE
var horizontal_direction: int = 1
var last_moved_tick: int = -1


func _init() -> void:
	pixel_color = Color.BLUE + Color(randf() * 0.4 - 0.2, randf() * 0.4 - 0.2, randf() * 0.4 - 0.2, 1)
	horizontal_direction = 1 if randf() < 0.5 else -1
