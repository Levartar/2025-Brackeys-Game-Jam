extends CharacterBody2D

@export var speed = 400
@export var rotation_speed = 1.5

var rotation_direction = 0
var deploying: bool = false
var last_deployment_state: bool = false
var trail: Line2D

func _ready() -> void:
  trail = get_parent().get_node("Trail")

func get_input():
  rotation_direction = Input.get_axis("left", "right")
  velocity = transform.y * -1 * speed
  deploying = Input.is_action_pressed("deploy")

func _process(_delta: float) -> void:
  if deploying != last_deployment_state:
    trail.deploying = !trail.deploying
    if deploying:
      trail.clear_points()
    last_deployment_state = deploying


func _physics_process(delta):
  get_input()
  rotation += rotation_direction * rotation_speed * delta
  move_and_slide()