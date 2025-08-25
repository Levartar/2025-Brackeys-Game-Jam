extends TextureRect

const TEX_SIZE := Vector2i(800, 800)
var seed: int = 0
var noise := FastNoiseLite.new()
var earth_img: Image
var earth_tex: ImageTexture

# Material colors
const COLOR_MOUNTAIN = Color(0.35, 0.01, 0.23, 1.0)
const COLOR_FOREST   = Color(0.75, 0.15, 0.26, 1.0)
const COLOR_GRASS    = Color(0.95, 0.38, 0.25, 1.0)
const COLOR_SAND     = Color(0.95, 0.82, 0.74, 1.0)
const COLOR_RIVER    = Color(0.04, 0.59, 0.65, 1.0)
#Color(0.04, 0.59, 0.65, 1.0)
#Color(0.15, 0.06, 0.15, 1.0)

func _ready():
  generate_map()
  update_texture()
  print("Generated map with seed: %d" % seed)

func generate_map(optional_seed: int = randi()):
  if optional_seed == -1:
    seed = randi()
  else:
    seed = optional_seed
  noise.seed = seed
  noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
  noise.frequency = 0.003

  earth_img = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
  for x in range(TEX_SIZE.x):
    for y in range(TEX_SIZE.y):
      var n = noise.get_noise_2d(x, y)
      # Map noise to material
      var color: Color
      if n < -0.4:
        color = COLOR_RIVER
      elif n < -0.1:
        color = COLOR_SAND
      elif n < 0.2:
        color = COLOR_GRASS
      elif n < 0.5:
        color = COLOR_FOREST
      else:
        color = COLOR_MOUNTAIN
      earth_img.set_pixel(x, y, color)

func update_texture():
  earth_tex = ImageTexture.create_from_image(earth_img)
  self.texture = earth_tex

func get_seed() -> int:
  return seed

func copy_seed_to_clipboard():
  DisplayServer.clipboard_set(str(seed))