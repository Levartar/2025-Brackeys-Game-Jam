extends Area2D

signal selected(room: Room)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var line_2d: Line2D = $Line2D
@onready var sprite: Sprite2D = $Sprite2D

const Room = preload("res://scripts/map/room.gd")


var available: bool = false
var room: Room : set = set_room
var room_seed: int = 0

func set_available(new_val: bool) -> void:
  available = new_val
  if available:
    animation_player.play("highlight")
  elif not room.selected:
    animation_player.play("RESET")


func set_room(new_room: Room) -> void:
  room = new_room
  position = room.position
  room_seed = room.room_seed

func show_picked() -> void:
  line_2d.modulate = Color.BURLYWOOD

func _on_map_room_selected(room: Room) -> void:
  if room == self.room and available:
    selected.emit(room)
    animation_player.play("selected")
    line_2d.modulate = Color.BURLYWOOD
    print("Room selected: ", room.row, ", ", room.column)

func _input_event(_viewport, event, _shape_idx):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if available:
            animation_player.play("selected")
            selected.emit(room)

