extends Line2D

@export var max_points: int = 100
@export var min_distance: int = 5
@export var longevity: float = 0.5

var plane: CharacterBody2D
var is_active: bool = true

func _ready() -> void:
  clear_points()
  plane = get_parent().get_node("Plane")

func _process(_delta):
  if is_active:
    if plane == null: print("Trail could not find Plane instance!"); return
    var pos = plane.global_position
    if (points.is_empty() or pos.distance_to(points[-1]) > min_distance):
      add_point(pos)

    if points.size() > max_points:
      deactivate()
      plane.activate_cooldown()

func deactivate() -> void:
  is_active = false
  await get_tree().create_timer(longevity).timeout
  var tween = get_tree().create_tween()
  tween.tween_property(self, "modulate:a", 0.0, 1.0)
  await tween.finished
  queue_free()
