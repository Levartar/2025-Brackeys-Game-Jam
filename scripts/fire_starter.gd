extends Node2D

const TEX_SIZE := Vector2i(800, 800)

@onready var earth_rect: TextureRect = $Layers/EarthTexture
@onready var fire_rect: TextureRect = $Layers/FireTexture
@onready var water_rect: TextureRect = $Layers/WaterTexture
@onready var label: Label = $Label


var earth_img: Image
var fire_img: Image
var water_img: Image
var earth_tex: ImageTexture
var fire_tex: ImageTexture
var water_tex: ImageTexture
var burning_pixels := {}

const ash_col = Color(0.2, 0.2, 0.2, 1.0)
const alpha_col = Color(0, 0, 0, 0)

func ignite_area(rect: Rect2i):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			ignite_pixel(Vector2i(x, y))

func ignite_pixel(pos: Vector2i):
	fire_img.set_pixel(pos.x, pos.y, Color(1, 10.0, 0, 1)) # burning, 10s lifetime in green channel
	burning_pixels[pos] = true
	_update_fire_texture()

func _ready():
	# Create images
	earth_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	fire_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	water_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)

	# Fill earth with forest (green) and grass (light green) randomly
	for x in TEX_SIZE.x:
		for y in TEX_SIZE.y:
			var is_forest = randf() < 0.5
			var color = Color(0.1, 0.6, 0.1, 1.0) if is_forest else Color(0.4, 0.8, 0.2, 1.0)
			earth_img.set_pixel(x, y, color)
			fire_img.set_pixel(x, y, Color(0, 0, 0, 0))
			water_img.set_pixel(x, y, Color(0, 0, 0, 0))

	# Create textures
	earth_tex = ImageTexture.create_from_image(earth_img)
	fire_tex = ImageTexture.create_from_image(fire_img)
	water_tex = ImageTexture.create_from_image(water_img)

	# Assign textures to ColorRects
	earth_rect.texture = earth_tex
	fire_rect.texture = fire_tex
	water_rect.texture = water_tex

	#ignite_pixel(Vector2i(500, 500))
	ignite_area(Rect2i(Vector2i(400, 400), Vector2i(50, 50)))


func throw_water(rect: Rect2i):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			water_img.set_pixel(x, y, Color(0, 0, 1, 1)) # wet
	_update_water_texture()

func _update_earth_texture():
	earth_tex.update(earth_img)

func _update_fire_texture():
	fire_tex.update(fire_img)

func _update_water_texture():
	water_tex.update(water_img)

# Ignite a random neighbor of a burning pixel
func ignite_random_neighbor(pos: Vector2i, to_ignite: Array) -> void:
	var neighbors = [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]
	var n = neighbors[randi() % neighbors.size()]
	var nx = pos.x + n.x
	var ny = pos.y + n.y
	if nx >= 0 and nx < TEX_SIZE.x and ny >= 0 and ny < TEX_SIZE.y and earth_img.get_pixel(nx, ny).r != 0.2:
		to_ignite.append(Vector2i(nx, ny))


func _process(delta):
	var fps = Engine.get_frames_per_second()
	label.text = "FPS: %d\nBurning Pixels: %d" % [fps, burning_pixels.size()]

	var to_ignite = []
	var to_remove = []
	for pos in burning_pixels.keys():
		var bx = pos.x
		var by = pos.y
		var fire_val = fire_img.get_pixel(bx, by)
		if fire_val.r > 0.5:
			# Extinguish if water or ash present
			var water_val = water_img.get_pixel(bx, by)
			var earth_val = earth_img.get_pixel(bx, by)
			if water_val.b > 0.5 or is_equal_approx(earth_val.r, 0.2): # ash or wet
				fire_img.set_pixel(bx, by, alpha_col)
				to_remove.append(pos)
				continue
			# Decrease lifetime
			fire_val.g -= delta
			# If lifetime over, turn to ash
			if fire_val.g <= 0.0:
				fire_img.set_pixel(bx, by, alpha_col)
				earth_img.set_pixel(bx, by, ash_col)
				to_remove.append(pos)
			else:
				if int(fire_val.g * 4) != int((fire_val.g + delta) * 4): # triggers every 0.33s
					ignite_random_neighbor(Vector2i(bx, by), to_ignite)
				fire_img.set_pixel(bx, by, Color(fire_val.r, fire_val.g, fire_val.b, fire_val.a))
		else:
			to_remove.append(pos)
	# Ignite new fires
	for pos in to_ignite:
		var fire_val = fire_img.get_pixel(pos.x, pos.y)
		if fire_val.r < 0.8:
			fire_img.set_pixel(pos.x, pos.y, Color(1, 10.0, 0, 1))
			burning_pixels[pos] = true
	# Remove extinguished or burned out pixels
	for pos in to_remove:
		burning_pixels.erase(pos)
	_update_fire_texture()
	_update_earth_texture()
