extends Area2D
class_name MapRoom

signal selected(room: Room, seed: int)
signal clicked(room: Room)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var line_2d: Line2D = $Node2D/Line2D
@onready var sprite: Sprite2D = $Node2D/Sprite2D
@onready var texture_rect: TextureRect = $Node2D/TextureRect

var row: int
var column: int
var next_rooms: Array[MapRoom] = []

var available: bool = false
var room: Room : set = set_room
var room_seed: int = 0
var type: Room.Type = Room.Type.NOT_ASSIGNED

func _ready() -> void:
  room_seed = texture_rect.get_seed()
  #if room_seed != 0:
  #  texture_rect.generate_map(room_seed)

func set_available(new_val: bool) -> void:
  available = new_val
  if available:
    animation_player.play("highlight")
  elif not room.selected:
    animation_player.play("RESET")

func set_room(new_room: Room) -> void:
  room = new_room
  position = room.position

func update_texture_rect() -> void:
    texture_rect.generate_map(room_seed)
    print("Updated texture rect with seed: %d" % room_seed)

func show_picked() -> void:
  line_2d.modulate = Color.BURLYWOOD

func _on_map_room_selected(room: MapRoom) -> void:
  if room == self and available:
    selected.emit(room, texture_rect.seed)
    if line_2d.visible == false:
      animation_player.play("RESET")
      animation_player.play("selected")
      line_2d.visible = true

func unselect() -> void:
  line_2d.visible = false
  if available:
    animation_player.play("highlight")
  else:
    animation_player.play("RESET")

func _input_event(_viewport, event, _shape_idx):
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    #if available:
    _on_map_room_selected(self)

