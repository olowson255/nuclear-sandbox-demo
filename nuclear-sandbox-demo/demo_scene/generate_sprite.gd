extends Sprite2D

const TEX_WIDTH := 160
const TEX_HEIGHT := 90
const UPDATE_FPS := 60.0
const BRUSH_RADIUS := 3

var simulation: Simulation
var image: Image
var accumulator := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	position = Vector2.ZERO
	
	simulation = Simulation.new(TEX_WIDTH, TEX_HEIGHT)
	
	image = Image.create(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	render()
	
	scale = get_viewport_rect().size / Vector2(TEX_WIDTH, TEX_HEIGHT)


func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var p := get_local_mouse_position()
		simulation.spawn_circle(floori(p.x), floori(p.y), BRUSH_RADIUS)
	
	accumulator += delta
	var step := 1.0 / UPDATE_FPS
	if accumulator >= step:
		accumulator = fmod(accumulator, step)
		simulation.step()
		render()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		simulation.clear()


func render() -> void:
	image.set_data(TEX_WIDTH, TEX_HEIGHT, false, Image.FORMAT_RGBA8, simulation.get_pixels())
	(texture as ImageTexture).update(image)
