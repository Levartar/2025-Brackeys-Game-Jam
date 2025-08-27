extends Sprite2D

@export var delay: float = 1.0
@export var distinguish_radius: int = 55
@export var longevity: float = 0.5
@export var fadout_duration: float = 0.5

var plane: CharacterBody2D
var terrain: Control

func _ready() -> void:
  plane = get_parent().get_node("Plane")
  terrain = get_parent().get_node("Terrain")
  position = plane.position
  # default_color = Color.WHITE

func _process(_delta):
  pass

func deploy() -> void:
    if plane == null: print("Bomb could not find Plane instance!"); return
    var pos = plane.position
    if terrain:
      terrain.drop_water_at_position(pos, distinguish_radius)
      deactivate()
      plane.activate_cooldown()

func deactivate() -> void:
  await get_tree().create_timer(longevity).timeout
  var tween = get_tree().create_tween()
  tween.tween_property(self, "modulate:a", 0.0, fadout_duration)
  await tween.finished
  queue_free()
