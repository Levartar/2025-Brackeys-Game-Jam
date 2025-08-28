extends Node2D

@export var poi_num: int = 3
@export var poi_border_margin: int = 75
@export var poi_min_distance: int = 150
@export var poi_fire_distance: int = 75

var is_any_poi_waiting: bool = false
var poi_scene: PackedScene = preload("res://scenes/poi.tscn")
var terrain: Control
var terrain_dim: Vector2i
var poi_place_incorrect: bool = true
var all_poi_positions: Array[Vector2]
var fire_spawn_pos: Vector2 = Vector2.ZERO # TODO: adjust fire spawns later on

func _ready() -> void:
  terrain = $Terrain
  terrain_dim = terrain.TEX_SIZE
  for i in range(poi_num):
    var new_pos = Vector2.ZERO
    while poi_place_incorrect:
      var pos_x = randi_range(poi_border_margin, terrain_dim.x - poi_border_margin)
      var pos_y = randi_range(poi_border_margin, terrain_dim.y - poi_border_margin)
      new_pos = Vector2(pos_x, pos_y)
      if not terrain.is_position_in_waters(new_pos): # check distance to waters
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
    var new_poi = poi_scene.instantiate()
    new_poi.position = new_pos
    add_child(new_poi)
    poi_place_incorrect = true

func _process(_delta: float) -> void:
  pass

func get_is_any_poi_waiting() -> bool:
  return is_any_poi_waiting

func set_is_any_poi_waiting(state: bool) -> void:
  is_any_poi_waiting = state
