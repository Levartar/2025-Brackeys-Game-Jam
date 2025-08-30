extends CharacterBody2D

enum PlaneType {Standard, Bomber, Laser}

@export var type: PlaneType = PlaneType.Standard
@export var speed: int = 400
@export var rotation_speed: float = 1.5
@export var cooldown_values = {"Standard": 1.5, "Bomber": 1.5, "Laser": 0.0}
@export var is_test: bool = false # TODO: make sure is set to false in godot before release

var rotation_direction: float = 0
var last_rotation_is_left: bool = false

var deploying: bool = false
var last_deployment_state: bool = false
var trail_scene: PackedScene = preload("res://scenes/trail.tscn")
var bomb_scene: PackedScene = preload("res://scenes/bomb.tscn")
var laser_scene: PackedScene = preload("res://scenes/laser.tscn")
var latest_trail: Node

var cooldown
var cooling_down: bool = false
var current_cool_down: float = 0.0
var deployed_after_cooldown: bool = false

var texture_standard: Texture2D = preload("res://assets/planes/standard.png")
var texture_bomber: Texture2D = preload("res://assets/planes/bomber.png")
var texture_laser: Texture2D = preload("res://assets/planes/laser.png")
var sprite: Sprite2D

var sfx_standard: AudioStreamWAV = preload("res://assets/sfx/propeller-standard.wav")
var sfx_bomber: AudioStreamWAV = preload("res://assets/sfx/propeller-bomber.wav")
var sfx_laser: AudioStreamWAV = preload("res://assets/sfx/propeller-laser.wav")
var audio_player: AudioStreamPlayer2D

var is_over_poi: bool = false
var poi_interaction: Callable
var has_passengers: bool = false

# testing vars
var initial_position: Vector2
var speed_mod: float = 1

func _ready() -> void:
  sprite = $Sprite2D
  audio_player = $AudioStreamPlayer2D
  initial_position = position

func _process(delta: float) -> void:
  if cooling_down:
    current_cool_down -= delta
    if current_cool_down <= 0:
      cooling_down = false
      current_cool_down = cooldown
      if sprite: sprite.modulate = Color(1, 1, 1, 1)
      deployed_after_cooldown = false
  else:
    if Input.is_action_just_pressed("deploy"):
      if type == PlaneType.Standard:
        latest_trail = trail_scene.instantiate()
        get_parent().add_child(latest_trail)
      elif type == PlaneType.Bomber:
        latest_trail = bomb_scene.instantiate()
        await get_tree().create_timer(latest_trail.delay).timeout
        get_parent().add_child(latest_trail)
        latest_trail.deploy()
      elif type == PlaneType.Laser:
        latest_trail = laser_scene.instantiate()
        add_child(latest_trail)
        latest_trail.deploy()
      deployed_after_cooldown = true
    elif Input.is_action_just_released("deploy"):
      if deployed_after_cooldown:
        if latest_trail: latest_trail.deactivate()
        activate_cooldown()
      deployed_after_cooldown = false

func _physics_process(delta):
  if Input.is_action_just_pressed("interact") and is_over_poi and poi_interaction:
    poi_interaction.call()
  rotation_direction = Input.get_axis("steer_left", "steer_right")
  if rotation_direction < 0: last_rotation_is_left = true
  elif rotation_direction > 0: last_rotation_is_left = false
  velocity = transform.y * -1 * speed * speed_mod
  rotation += rotation_direction * rotation_speed * delta
  move_and_slide()
  # testing controls
  if is_test:
    if Input.is_action_just_pressed("reset_plane"):
      position = initial_position
    if Input.is_action_pressed("boost_plane") and speed_mod == 1.0:
      speed_mod = 2.0
    elif !Input.is_action_pressed("boost_plane") and speed_mod == 2.0:
      speed_mod = 1.0;
    if Input.is_action_just_pressed("swap_plane_type"):
      set_type(get_next_type())

func activate_cooldown() -> void:
  if cooldown > 0:
    cooling_down = true
    if sprite: sprite.modulate = Color(0.8, 0.8, 0.8, 1.0) # mid-grey

func set_type(new_type: PlaneType) -> void:
  type = new_type
  if new_type == PlaneType.Standard:
    cooldown = cooldown_values["Standard"]
    sprite.texture = texture_standard
    audio_player.stream = sfx_standard
  elif new_type == PlaneType.Bomber:
    cooldown = cooldown_values["Bomber"]
    sprite.texture = texture_bomber
    audio_player.stream = sfx_bomber
  elif new_type == PlaneType.Laser:
    cooldown = cooldown_values["Laser"]
    sprite.texture = texture_laser
    audio_player.stream = sfx_laser
  cooling_down = false
  current_cool_down = 0.0
  audio_player.play()

func stop_audio() -> void:
  if audio_player: audio_player.stop()

func get_rand_type() -> int:
  return randi_range(0, PlaneType.size() - 1)
func get_next_type() -> int:
  return (type + 1) % 3

func set_pos(pos: Vector2) -> void:
  position = pos
func set_rot(rot: float) -> void:
  rotation_degrees = rot
func set_visibility(state: bool) -> void:
  visible = state

func set_is_over_poi(state: bool) -> void:
  is_over_poi = state
func set_poi_interaction(interaction: Callable) -> void:
  poi_interaction = interaction

func add_passengers() -> void:
  has_passengers = true
func remove_passengers() -> void:
  has_passengers = false
