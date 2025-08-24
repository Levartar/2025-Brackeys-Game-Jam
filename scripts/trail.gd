extends Line2D

@export var max_points = 50
@export var min_distance = 5

var plane: CharacterBody2D
var is_current: bool = true

func _ready() -> void:
  clear_points()
  plane = get_parent().get_node("Plane")

func _process(_delta):
  if plane == null: print("Trail could not find Plane instance!"); return
  if is_current:
    var pos = plane.global_position
    if (points.is_empty() or pos.distance_to(points[-1]) > min_distance):
      add_point(pos)

    if points.size() > max_points:
      is_current = false
      plane.activate_cooldown()
