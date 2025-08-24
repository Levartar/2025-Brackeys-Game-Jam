extends CharacterBody2D

@export var speed = 400
@export var rotation_speed = 1.5
@export var cool_down = 2.0

var rotation_direction = 0
var deploying: bool = false
var last_deployment_state: bool = false
var trail: Line2D
var trail_scene: PackedScene = preload("res://scenes/Trail.tscn")
var latest_trail: Node

var cooling_down: bool = false
var current_cool_down: float = 0.0

func _ready() -> void:
  current_cool_down = cool_down

func get_input():
  rotation_direction = Input.get_axis("left", "right")
  velocity = transform.y * -1 * speed
  deploying = Input.is_action_just_pressed("deploy")

func _process(delta: float) -> void:
  if cooling_down:
    current_cool_down -= delta
    if current_cool_down <= 0:
      cooling_down = false
      current_cool_down = cool_down
  else:
    if deploying:
      latest_trail = trail_scene.instantiate()
      get_parent().add_child(latest_trail)

    # if deploying != last_deployment_state:
    #   latest_trail = trail_scene.instantiate()
    #   get_parent().add_child(latest_trail)
    #   # if deploying: latest_trail.clear_points()
    #   last_deployment_state = deploying


func _physics_process(delta):
  get_input()
  rotation += rotation_direction * rotation_speed * delta
  move_and_slide()

func activate_cooldown() -> void:
  cooling_down = true
