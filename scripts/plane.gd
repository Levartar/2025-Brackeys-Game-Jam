extends CharacterBody2D

@export var speed = 400
@export var rotation_speed = 1.5

var rotation_direction = 0
var deploying: bool = false
@onready var color_rect = $ColorRect

func _ready() -> void:
  color_rect.visible = false

func get_input():
  rotation_direction = Input.get_axis("left", "right")
  velocity = transform.y * -1 * speed
  deploying = Input.is_action_pressed("deploy")

func _physics_process(delta):
  get_input()
  if deploying and not color_rect.visible:
    color_rect.visible = true
  elif not deploying and color_rect.visible:
    color_rect.visible = false
  rotation += rotation_direction * rotation_speed * delta
  move_and_slide()