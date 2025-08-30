extends Node2D

@export var poi_num: int = 3
@export var poi_border_margin: int = 75
@export var poi_min_distance: int = 150
@export var poi_fire_distance: int = 75

var is_any_poi_waiting: bool = false
var poi_scene: PackedScene = preload("res://scenes/poi.tscn")
var airport_scene: PackedScene = preload("res://scenes/airport.tscn")
var plane_scene: PackedScene = preload("res://scenes/plane.tscn")
var plane: CharacterBody2D
var terrain: Control
var terrain_dim: Vector2i
var poi_place_incorrect: bool = true
var all_poi_positions: Array[Vector2]
var fire_spawn_pos: Vector2 = Vector2.ZERO # TODO: adjust fire spawns later on
var airport_pos: Vector2
var airport_rot: float

func _ready() -> void:
  plane = $Plane
  terrain = $Terrain
  terrain_dim = terrain.TEX_SIZE
  for i in range(poi_num + 1):
    var new_pos = Vector2.ZERO
    while poi_place_incorrect:
      var pos_x = randi_range(poi_border_margin, terrain_dim.x - poi_border_margin)
      var pos_y = randi_range(poi_border_margin, terrain_dim.y - poi_border_margin)
      new_pos = Vector2(pos_x, pos_y)
      if not _is_close_to_waters(new_pos, 50.0): # check distance to waters
        var is_pos_too_close = false
        if new_pos.distance_to(fire_spawn_pos) < poi_fire_distance: # check distance to fire
          is_pos_too_close = true
        for j in range(all_poi_positions.size()):
          if is_pos_too_close: break
          if new_pos.distance_to(all_poi_positions[j]) < poi_min_distance: # check distance to other PoIs
            is_pos_too_close = true
        if not is_pos_too_close:
          all_poi_positions.append(new_pos)
          poi_place_incorrect = false
    if i < poi_num:
      var new_poi = poi_scene.instantiate()
      new_poi.position = new_pos
      add_child(new_poi)
      poi_place_incorrect = true
    else: # for last iteration add airport
      var airport = airport_scene.instantiate()
      airport_pos = new_pos
      airport.position = airport_pos
      var new_rot: Dictionary = _get_boundary_aware_rotation(400.0)
      airport_rot = randf_range(new_rot.min, new_rot.max)
      airport.rotation_degrees = airport_rot
      add_child(airport)
  swap_plane()

func _process(_delta: float) -> void:
  pass

func _is_close_to_waters(pos: Vector2, min_distance: float) -> bool:
  if terrain.is_position_in_waters(pos): return true
  if terrain.is_position_in_waters(pos + Vector2(min_distance, 0)): return true
  if terrain.is_position_in_waters(pos + Vector2(-min_distance, 0)): return true
  if terrain.is_position_in_waters(pos + Vector2(0, min_distance)): return true
  if terrain.is_position_in_waters(pos + Vector2(0, -min_distance)): return true
  return false

func _get_boundary_aware_rotation(threshold: float) -> Dictionary:
  var min_rot: float = 0.0
  var max_rot: float = 360.0
  if airport_pos.y < threshold: # A: should be downward oriented
    min_rot = 90.0
    max_rot = 270.0
  elif airport_pos.y > (terrain.TEX_SIZE.y - threshold): # B: should be upward oriented
    min_rot = 270.0
    max_rot = 90.0
  elif airport_pos.x < threshold: # C: should be right-facing
    min_rot = 0.0
    max_rot = 180.0
  elif airport_pos.x > (terrain.TEX_SIZE.x - threshold): # D: should be left-facing
    min_rot = 180.0
    max_rot = 360.0
  if airport_pos.y < threshold and airport_pos.x < threshold: # AC
    min_rot = 90.0
    max_rot = 180.0
  elif airport_pos.y < threshold and airport_pos.x > (terrain.TEX_SIZE.x - threshold): # AD
    min_rot = 180.0
    max_rot = 270.0
  elif airport_pos.y > (terrain.TEX_SIZE.y - threshold) and airport_pos.x < threshold: # BC
    min_rot = 0.0
    max_rot = 90.0
  elif airport_pos.y > (terrain.TEX_SIZE.y - threshold) and airport_pos.x > (terrain.TEX_SIZE.x - threshold): # BD
    min_rot = 270.0
    max_rot = 360.0
  return {"min": min_rot, "max": max_rot}

func swap_plane() -> void:
  plane.set_pos(airport_pos)
  plane.set_rot(airport_rot)
  plane.set_type(plane.get_rand_type())
  plane.remove_passengers()
  is_any_poi_waiting = false

func get_is_any_poi_waiting() -> bool:
  return is_any_poi_waiting

func set_is_any_poi_waiting(state: bool) -> void:
  is_any_poi_waiting = state
