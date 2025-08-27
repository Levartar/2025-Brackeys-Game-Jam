extends CharacterBody2D

enum PlaneType {Standard, Bomber}

@export var type: PlaneType = PlaneType.Standard
@export var speed: int = 400
@export var rotation_speed: float = 1.5
@export var cooldown_values = {"Standard": 1.5, "Bomber": 1.5}
@export var is_test: bool = false # TODO: make sure is set to false in godot before release

var rotation_direction: float = 0
var deploying: bool = false
var last_deployment_state: bool = false
var trail_scene: PackedScene = preload("res://scenes/trail.tscn")
var bomb_scene: PackedScene = preload("res://scenes/bomb.tscn")
var latest_trail: Node

var cooldown
var cooling_down: bool = false
var current_cool_down: float = 0.0
var deployed_after_cooldown: bool = false

var texture_standard: Texture2D = preload("res://assets/planes/standard.png")
var texture_bomber: Texture2D = preload("res://assets/planes/bomber.png")
var sprite: Sprite2D

# testing vars
var initial_position: Vector2
var speed_mod: float = 1

func _ready() -> void:
  if type == PlaneType.Standard: cooldown = cooldown_values["Standard"]
  elif type == PlaneType.Bomber: cooldown = cooldown_values["Bomber"]
  current_cool_down = cooldown
  initial_position = position
  sprite = $Sprite2D
  if type == PlaneType.Standard: sprite.texture = texture_standard
  elif type == PlaneType.Bomber: sprite.texture = texture_bomber

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
      deployed_after_cooldown = true
    elif Input.is_action_just_released("deploy"):
      if deployed_after_cooldown:
        if latest_trail: latest_trail.deactivate()
        activate_cooldown()
      deployed_after_cooldown = false

func _physics_process(delta):
  rotation_direction = Input.get_axis("left", "right")
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
      speed_mod = 1.0; print("reset speed_mod")

func activate_cooldown() -> void:
  cooling_down = true
  if sprite: sprite.modulate = Color(0.8, 0.8, 0.8, 1.0) # mid-grey
