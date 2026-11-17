class_name Simulation
extends RefCounted

var width: int
var height: int
var tick := 0

var _grid: Array = []
var _pixels := PackedByteArray()


func _init(w: int, h: int) -> void:
	width = w
	height = h
	_pixels.resize(width * height * 4)
	_build_grid()


# PUBLIC API

func step() -> void:
	tick += 1
	for y in range(height - 1, -1, -1):
		for xPos in width:
			var x = xPos if tick % 2 == 0 else width - (xPos+1)
			if _is_empty(x, y):
				continue
			
			var m: Molecule = _grid[x][y]
			if m.last_moved_tick == tick:
				continue
			
			# 1. Down
			if _is_empty(x, y + 1):
				_move_molecule(x, y, x, y + 1)
				continue
			
			# 2. Angle
			if _is_empty(x + m.horizontal_direction, y + 1):
				_move_molecule(x, y, x + m.horizontal_direction, y + 1)
				continue
			
			# 3. Side
			if _is_empty(x + m.horizontal_direction, y):
				_move_molecule(x, y, x + m.horizontal_direction, y)
				continue
			
			# 4. Turn around since blocked
			m.horizontal_direction = -m.horizontal_direction


func spawn_circle(cx: int, cy: int, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var x := cx + dx
			var y := cy + dy
			if _is_empty(x, y):
				_set_molecule(x, y, Molecule.new())


func clear() -> void:
	for x in width:
		for y in height:
			_grid[x][y] = null


func get_pixels() -> PackedByteArray:
	var i := 0
	for y in height:
		for x in width:
			var m: Molecule = _grid[x][y]
			if m == null:
				_pixels[i] = 0
				_pixels[i + 1] = 0
				_pixels[i + 2] = 0
				_pixels[i + 3] = 0
			else:
				var c := m.pixel_color
				_pixels[i] = c.r8
				_pixels[i + 1] = c.g8
				_pixels[i + 2] = c.b8
				_pixels[i + 3] = c.a8
			i += 4
	return _pixels


# INTERNALS

func _build_grid() -> void:
	_grid.clear()
	for x in width:
		var column: Array = []
		column.resize(height)
		_grid.append(column)


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


func _is_empty(x: int, y: int) -> bool:
	return _in_bounds(x, y) and _grid[x][y] == null


func _set_molecule(x: int, y: int, m: Molecule) -> void:
	if _in_bounds(x, y):
		_grid[x][y] = m


func _move_molecule(x: int, y: int, tx: int, ty: int) -> void:
	var m: Molecule = _grid[x][y]
	_grid[tx][ty] = m
	_grid[x][y] = null
	m.last_moved_tick = tick
