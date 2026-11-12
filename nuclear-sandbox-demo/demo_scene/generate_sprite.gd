extends Sprite2D

const TEX_WIDTH := 160
const TEX_HEIGHT := 90
const UPDATE_FPS := 40.0
const BRUSH_RADIUS := 3

class Molecule:
	var pixel_color: Color = Color.BLUE
	var horizontal_direction: int = 1
	var frozen: bool = false
	var last_moved_tick: int = -1
	
	func _init() -> void:
		pixel_color = Color.BLUE + Color(randf()*0.4-0.2, randf()*0.4-0.2, randf()*0.4-0.2, 1)
		horizontal_direction = 1 if randf() < 0.5 else -1

var grid: Array = []
var image: Image
var bytes := PackedByteArray()
var accumulator := 0.0
var tick := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	position = Vector2.ZERO
	
	bytes.resize(TEX_WIDTH * TEX_HEIGHT * 4)
	image = Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	
	build_grid()
	render()
	
	scale = get_viewport_rect().size / Vector2(TEX_WIDTH, TEX_HEIGHT)

func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		spawn_at_mouse()
	
	accumulator += delta
	var step := 1.0 / UPDATE_FPS
	if accumulator >= step:
		accumulator = fmod(accumulator, step)
		
		simulation_step()
		render()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		clear_all()

# ONE TIMERS
func build_grid() -> void:
	grid.clear()
	for x in TEX_WIDTH:
		var column: Array = []
		column.resize(TEX_HEIGHT)
		grid.append(column)

# UTIL
func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < TEX_WIDTH and y < TEX_HEIGHT

func get_molecule(x: int, y: int) -> Molecule:
	return grid[x][y] if in_bounds(x, y) else null

func set_molecule(x: int, y: int, m: Molecule) -> void:
	if in_bounds(x, y):
		grid[x][y] = m

func clear_cell(x: int, y: int) -> void:
	set_molecule(x, y, null)

func is_empty(x: int, y: int) -> bool:
	return in_bounds(x, y) and grid[x][y] == null

func move_molecule(m: Molecule, x: int, y: int, nx: int, ny: int) -> void:
	grid[nx][ny] = m
	grid[x][y] = null
	m.last_moved_tick = tick

func clear_all() -> void:
	for x in TEX_WIDTH:
		for y in TEX_HEIGHT:
			grid[x][y] = null



func spawn_at_mouse() -> void:
	var p := get_local_mouse_position()
	var cx := floori(p.x)
	var cy := floori(p.y)
	for dy in range(-BRUSH_RADIUS, BRUSH_RADIUS + 1):
		for dx in range(-BRUSH_RADIUS, BRUSH_RADIUS + 1):
			# circular brush
			if dx * dx + dy * dy > BRUSH_RADIUS * BRUSH_RADIUS:
				continue
			var x := cx + dx
			var y := cy + dy
			if is_empty(x, y):
				set_molecule(x, y, Molecule.new())

func simulation_step() -> void:
	tick += 1
	for y in range(TEX_HEIGHT - 1, -1, -1):
		for x in TEX_WIDTH:
			if is_empty(x, y):
				continue
			
			var m: Molecule = grid[x][y]
			if m.last_moved_tick == tick:
				continue
			
			# 1. Down
			if is_empty(x, y + 1):
				move_molecule(m, x, y, x, y + 1)
				continue

			# 2. Angle: one row down, one cell in the molecule's direction
			if is_empty(x + m.horizontal_direction, y + 1):
				move_molecule(m, x, y, x + m.horizontal_direction, y + 1)
				continue

			# 3. Side
			if is_empty(x + m.horizontal_direction, y):
				move_molecule(m, x, y, x + m.horizontal_direction, y)
				continue
				
			# 3. Turn around since blocked
			m.horizontal_direction = -m.horizontal_direction
			
			# 4. Freeze if all paths blocked
			#if not is_empty(x, y + 1) and not is_empty(x - 1, y) and not is_empty(x + 1, y):
				#m.frozen = true

func render() -> void:
	var i := 0
	for y in TEX_HEIGHT:
		for x in TEX_WIDTH:
			var m: Molecule = grid[x][y]
			if m == null:
				bytes[i] = 0
				bytes[i + 1] = 0
				bytes[i + 2] = 0
				bytes[i + 3] = 0
			else:
				var c := m.pixel_color
				bytes[i] = c.r8
				bytes[i + 1] = c.g8
				bytes[i + 2] = c.b8
				bytes[i + 3] = c.a8
			i += 4
	image.set_data(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8, bytes)
	(texture as ImageTexture).update(image)
