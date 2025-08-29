extends Node2D

@export var plane_swap_time: float = 0.5

var flight_sim: Node2D
var plane: CharacterBody2D

func _ready() -> void:
  flight_sim = get_parent()
  plane = get_parent().get_node("Plane")

func _on_body_entered(body: Node2D) -> void:
  if body.name == "Plane" and plane.has_passengers:
    plane.set_visibility(false)
    await get_tree().create_timer(plane_swap_time).timeout
    flight_sim.swap_plane()
    plane.set_visibility(true)
