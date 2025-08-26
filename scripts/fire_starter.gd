extends Node2D

const TEX_SIZE := Vector2i(800, 800)

@onready var earth_rect: TextureRect = $Layers/EarthTexture
@onready var fire_rect: TextureRect = $Layers/FireTexture
@onready var water_rect: TextureRect = $Layers/WaterTexture
@onready var label: Label = $Label

const MATERIALS = preload("res://scripts/earth_texture.gd").MATERIALS
var color_to_material = {} #Lookup HashMap


var earth_img: Image
var fire_img: Image
var water_img: Image
var earth_tex: ImageTexture
var fire_tex: ImageTexture
var water_tex: ImageTexture

# Burning pixel management
var burning_pixels := {}           # Dictionary: pos -> true
var burning_pixel_keys := []       # Array of Vector2i
var chunk_index := 0
const CHUNK_DIVISOR = 10

const ash_col = Color(0.2, 0.2, 0.2, 1)
const alpha_col = Color(0, 0, 0, 0)

func _ready():
	# Create images
	earth_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	fire_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	water_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)

	# Init earth image from EarthTexture node
	var earth_node = earth_rect
	if earth_node.texture and earth_node.texture is ImageTexture:
		earth_img = earth_node.texture.get_image().duplicate()
	else:
		push_error("EarthTexture node does not have a valid ImageTexture!")
		return

	#Init material lookup
	for mat_name in MATERIALS.keys():
		var mat_col = MATERIALS[mat_name].color
		var key = color_to_key(mat_col)
		color_to_material[key] = MATERIALS[mat_name]

	fire_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	water_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)

	# Create textures
	earth_tex = ImageTexture.create_from_image(earth_img)
	fire_tex = ImageTexture.create_from_image(fire_img)
	water_tex = ImageTexture.create_from_image(water_img)

	# Assign textures to TextureRects
	earth_rect.texture = earth_tex
	fire_rect.texture = fire_tex
	water_rect.texture = water_tex

	ignite_area(Rect2i(Vector2i(TEX_SIZE.x/2, TEX_SIZE.y/2), Vector2i(10, 10)))

func ignite_area(rect: Rect2i):
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			ignite_pixel(Vector2i(x, y)) # change indentation

func ignite_pixel(pos: Vector2i):
	if not burning_pixels.has(pos):
		burning_pixels[pos] = true
		burning_pixel_keys.append(pos)
		fire_img.set_pixel(pos.x, pos.y, Color(1, 1.0, 0, 1))

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
	var neighbors = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	var n = neighbors[randi() % neighbors.size()]
	var nx = pos.x + n.x
	var ny = pos.y + n.y
	if nx >= 0 and nx < TEX_SIZE.x and ny >= 0 and ny < TEX_SIZE.y:
		to_ignite.append(Vector2i(nx, ny))


func _process(_delta):
	var fps = Engine.get_frames_per_second()
	label.text = "FPS: %d\nBurning Pixels: %d" % [fps, burning_pixels.size()]

	var total = burning_pixel_keys.size()
	if total == 0:
		return
	var chunk_size = int(ceil(total / float(CHUNK_DIVISOR)))
	var start = chunk_index * chunk_size
	var end = min(start + chunk_size, total)
	var to_remove = []
	var to_ignite = []
	for i in range(start, end):
		var pos = burning_pixel_keys[i]
		var bx = pos.x
		var by = pos.y
		var fire_val = fire_img.get_pixel(bx, by)
		if fire_val.r > 0.5:
			var water_col = water_img.get_pixel(bx, by)
			var earth_col = earth_img.get_pixel(bx, by)
			var pixel_mat = get_material_from_color(earth_col)
			# Remove if earth material is ash, sand, or river, or if water is present
			if water_col.b > 0.5 \
				or earth_col.r <=0.4\
				or earth_col.b >=0.6:
				to_remove.append(pos)
				continue
			fire_val.g -= (1.0 / pixel_mat["lifetime"])* (int(CHUNK_DIVISOR) / 60.0) #pixel_mat["lifetime"] Lifetime in triggers per second
			if randf() <= pixel_mat["ignition_chance"]:
				ignite_random_neighbor(Vector2i(bx, by), to_ignite)
			if fire_val.g <= 0.0:
				to_remove.append(pos)
			else:
				fire_img.set_pixel(bx, by, Color(fire_val.r, fire_val.g, fire_val.b, fire_val.a))
		else:
			to_remove.append(pos)
	# Ignite new fires
	for pos in to_ignite:
		ignite_pixel(pos)
	# Remove extinguished or burned out pixels from both dict and key array
	for pos in to_remove:
		_extinguish_pixel(pos)
	chunk_index = (chunk_index + 1) % CHUNK_DIVISOR
	_update_fire_texture()
	_update_earth_texture()

func _extinguish_pixel(pos: Vector2i):
	burning_pixels.erase(pos)
	var idx = burning_pixel_keys.find(pos)
	fire_img.set_pixel(pos.x, pos.y, alpha_col)
	var old_col = earth_img.get_pixel(pos.x, pos.y)
	var new_col = old_col.lerp(ash_col, 0.5)
	earth_img.set_pixel(pos.x, pos.y, new_col)
	if idx != -1:
		burning_pixel_keys.remove_at(idx)
		
# Convert world position to texture coordinates
func world_to_texture_coords(world_pos: Vector2) -> Vector2i:
	# Assuming the fire texture covers the entire screen/viewport
	# You'll need to adjust this based on your actual setup
	var texture_pos = world_pos # Adjust scaling/offset as needed
	return Vector2i(int(texture_pos.x), int(texture_pos.y))

# Check if a world position intersects with fire
func is_position_on_fire(world_pos: Vector2) -> bool:
	var tex_pos = world_to_texture_coords(world_pos)
	if tex_pos.x >= 0 and tex_pos.x < TEX_SIZE.x and tex_pos.y >= 0 and tex_pos.y < TEX_SIZE.y:
		return burning_pixels.has(tex_pos)
	return false

# Drop water at world position
func drop_water_at_position(world_pos: Vector2, radius: int = 10):
	var tex_pos = world_to_texture_coords(world_pos)
	var rect = Rect2i(tex_pos.x - radius, tex_pos.y - radius, radius * 2, radius * 2)
	throw_water(rect)

func color_to_key(color: Color) -> String:
		# Round to 2 decimal places for tolerance
		return "%0.2f,%0.2f,%0.2f" % [color.r, color.g, color.b]

func get_material_from_color(color: Color):
	var key = color_to_key(color)
	if color_to_material.has(key):
		return color_to_material[key]
	return MATERIALS["none"]
