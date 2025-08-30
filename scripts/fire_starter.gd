extends Control

const TEX_SIZE := Vector2i(800, 800)

@onready var earth_rect: TextureRect = $Layers/EarthTexture
@onready var fire_rect: TextureRect = $Layers/FireTexture
@onready var water_rect: TextureRect = $Layers/WaterTexture
@onready var label: Label = $Label

const MATERIALS = preload("res://scripts/earth_texture.gd").MATERIALS
var color_to_material = {} # Lookup HashMap


var earth_img: Image
var fire_img: Image
var water_img: Image
var earth_tex: ImageTexture
var fire_tex: ImageTexture
var water_tex: ImageTexture

var audio_player: AudioStreamPlayer2D
@export var fire_sfx_fade_duration: float = 3.0

# Burning pixel management
var burning_pixels := {} # Dictionary: pos -> true
var burning_pixel_keys := [] # Array of Vector2i
var chunk_index := 0
const CHUNK_DIVISOR = 10

const ash_col = Color(0.2, 0.2, 0.2, 1)
const alpha_col = Color(0, 0, 0, 0)

var timer = 0
@export var water_longevity: float = 3
@export var water_fade_steps: float = 4
var water_pixels = {} # Dictionary: Vector2i -> alpha_value
var water_pixel_keys = []

@export var fires_num_min: int = 2
@export var fires_num_max: int = 7
@export var fires_min_distance: int = 100
@export var fires_border_margin: int = 50

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

  # Spawn fires
  var all_fire_pos: Array[Vector2i] = []
  var max_tries: int = 1000
  for i in randi_range(fires_num_min, fires_num_max):
    var new_pos = null
    var too_close_to_others: bool = false
    var num_tries: int = 0
    var aborted: bool = false
    while new_pos == null or is_position_in_waters(new_pos) or too_close_to_others:
      var new_pos_x: int = randi_range(fires_border_margin, TEX_SIZE.x - fires_border_margin)
      var new_pos_y: int = randi_range(fires_border_margin, TEX_SIZE.y - fires_border_margin)
      new_pos = Vector2i(new_pos_x, new_pos_y)
      for j in range(all_fire_pos.size()):
        if new_pos.distance_to(all_fire_pos[j]) < fires_min_distance:
          too_close_to_others = true
      num_tries += 1
      if num_tries >= max_tries:
        # print("Didn't find suitable spot to start fire within " + str(num_tries) + " tries.") # test
        aborted = true
        max_tries *= 2 # increase number to reduce chance of another fire not spawning
        break
    if not aborted:
      ignite_area(Rect2i(new_pos, Vector2i(10, 10)))
      all_fire_pos.append(new_pos)
      # print("Started fire at ", new_pos) # test

  # Play fire SFX
  audio_player = $AudioStreamPlayer2D
  audio_player.play()

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
      if x >= 0 and x < TEX_SIZE.x and y >= 0 and y < TEX_SIZE.y:
        water_img.set_pixel(x, y, Color(0, 0, 1, 1)) # wet
  _update_water_texture()

func throw_water_circle(center: Vector2i, radius: int):
  var radius_squared = radius * radius
  for x in range(center.x - radius, center.x + radius + 1):
    for y in range(center.y - radius, center.y + radius + 1):
      if x >= 0 and x < TEX_SIZE.x and y >= 0 and y < TEX_SIZE.y:
        var dx = x - center.x
        var dy = y - center.y
        var distance_squared = dx * dx + dy * dy
        if distance_squared <= radius_squared:
          var pos = Vector2i(x, y)
          if not water_pixels.has(pos):
            water_pixel_keys.append(pos)
          water_pixels[pos] = 1.0
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

  timer += _delta
  if timer >= water_longevity / water_fade_steps:
    timer -= water_longevity / water_fade_steps
    fade_water(1 / water_fade_steps)
    _update_water_texture()

  var total = burning_pixel_keys.size()
  if total == 0:
    var tween := create_tween()
    tween.tween_property(audio_player, "volume_db", -80.0, fire_sfx_fade_duration)
    tween.tween_callback(Callable(audio_player, "stop"))
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
        or earth_col.r <= 0.4 \
        or earth_col.b >= 0.6:
        to_remove.append(pos)
        continue
      fire_val.g -= (1.0 / pixel_mat["lifetime"]) * (int(CHUNK_DIVISOR) / 60.0) # pixel_mat["lifetime"] Lifetime in triggers per second
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

func fade_water(fade_rate: float):
  var to_remove = []
  for pos in water_pixel_keys:
    var current_alpha = water_pixels[pos] - fade_rate
    if current_alpha < 0.01:
      water_img.set_pixel(pos.x, pos.y, Color(0, 0, 1, 0))
      to_remove.append(pos)
    else:
      water_pixels[pos] = current_alpha
      water_img.set_pixel(pos.x, pos.y, Color(0, 0, 1, current_alpha))

  for pos in to_remove:
    water_pixels.erase(pos)
    water_pixel_keys.erase(pos)

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

# Check if a world position is in original water (from map generation)
func is_position_in_waters(world_pos: Vector2) -> bool:
  var tex_pos = world_to_texture_coords(world_pos)
  if tex_pos.x >= 0 and tex_pos.x < TEX_SIZE.x and tex_pos.y >= 0 and tex_pos.y < TEX_SIZE.y:
    var earth_color = earth_img.get_pixel(tex_pos.x, tex_pos.y)
    # Check if it's water/river color (blue component >= 0.6 based on your fire logic)
    return earth_color.b >= 0.6
  return false

# Drop water at world position
func drop_water_at_position(world_pos: Vector2, radius: int = 10):
  var tex_pos = world_to_texture_coords(world_pos)
  throw_water_circle(tex_pos, radius)

func color_to_key(color: Color) -> String:
    # Round to 2 decimal places for tolerance
    return "%0.2f,%0.2f,%0.2f" % [color.r, color.g, color.b]

func get_material_from_color(color: Color):
  var key = color_to_key(color)
  if color_to_material.has(key):
    return color_to_material[key]
  return MATERIALS["none"]

func _on_copy_seed_pressed() -> void:
  $Layers/EarthTexture.copy_seed_to_clipboard()
