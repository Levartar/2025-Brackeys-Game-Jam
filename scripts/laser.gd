extends Line2D

@export var distinguish_radius: int = 5
@export var trail_width: int = 5
@export var laser_range: int = 50
@export var laser_speed: float = 2.0
@export var laser_spread: int = 15

var plane: CharacterBody2D
var terrain: Control
var angle: float
var anchor: Vector2 = Vector2.ZERO

var is_active: bool = true
var range_mod: float

var audio_player: AudioStreamPlayer2D

func _ready() -> void:
  clear_points()
  plane = get_parent()
  terrain = get_parent().get_parent().get_node("Terrain")
  width = trail_width
  z_as_relative = false
  set_range_mod()
  points = [anchor, anchor + Vector2(laser_range * range_mod, 0)]
  audio_player = $AudioStreamPlayer2D
  audio_player.play()

func _process(delta):
  if not plane.is_water_in_tank(): deactivate()
  elif is_active:
    angle += laser_speed * delta
    var oscillation = sin(angle * 3.0) # x3 for faster oscillation
    var min_deg = - laser_spread # + deg_mod
    var max_deg = laser_spread # + deg_mod
    var oscillated_angle = deg_to_rad(lerp(min_deg, max_deg, (oscillation + 1.0) / 2.0))
    var moving_end = anchor + Vector2(cos(oscillated_angle) * laser_range * range_mod, sin(oscillated_angle) * laser_range)
    points[1] = moving_end
    var pos = plane.position + moving_end.rotated(plane.rotation)
    if terrain:
      terrain.drop_water_at_position(pos, distinguish_radius)
      plane.deplete_tank(delta)

func deploy() -> void:
    if plane == null: print("Laser could not find Plane instance!"); return
    set_range_mod()

func deactivate() -> void:
  is_active = false
  audio_player.stop()
  queue_free()

func set_range_mod() -> void:
  if plane.last_rotation_is_left and range_mod != -1: range_mod = -1
  elif !plane.last_rotation_is_left and range_mod != 1: range_mod = 1
