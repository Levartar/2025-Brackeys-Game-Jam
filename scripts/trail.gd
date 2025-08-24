extends Line2D

@export var max_points = 50
@export var min_distance = 5

var plane: CharacterBody2D
var deploying: bool

func _ready() -> void:
  clear_points()
  plane = get_parent().get_node("Plane")

func _process(_delta):
  if plane == null:
    return

  var pos = plane.global_position

  if deploying and (points.is_empty() or pos.distance_to(points[-1]) > min_distance):
    add_point(pos)

  while points.size() > max_points:
    clear_points()
