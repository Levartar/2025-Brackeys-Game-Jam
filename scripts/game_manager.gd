extends Node2D

var map_seed: int = 0
var is_lost: bool = false
var is_won: bool = false

func flag_lost() -> void:
  is_lost = true
  restart_after_delay(5)
func flag_won() -> void:
  is_won = true
  restart_after_delay(5)

func restart_after_delay(delay: float) -> void:
  await get_tree().create_timer(delay).timeout
  is_lost = false
  is_won = false
  get_tree().change_scene_to_file("res://scenes/game.tscn")
