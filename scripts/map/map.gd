extends Control
class_name Map

const SCROLL_SPEED := 15
const MAP_ROOM = preload("res://scenes/map/room_click.tscn")
const MAP_LINE = preload("res://scenes/map/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D

var map_data: Array[Array]
var floors_climbed: int
var last_room: MapRoom
var camera_edge_y: float


func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)

	generate_new_map()
	unlock_floor(0)

# scrolling system
#func _unhandled_input(event: InputEvent) -> void:
#	if not visible:
#		return
#	
#	if event.is_action_pressed("scroll_up"):
#		camera_2d.position.y -= SCROLL_SPEED
#		print("Camera Y:", camera_2d.position.y)
#	elif event.is_action_pressed("scroll_down"):
#		camera_2d.position.y += SCROLL_SPEED
#
#	camera_2d.position.y = clamp(camera_2d.position.y, -camera_edge_y, 0)


func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: MapRoom) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed
	create_map()
	
	#if floors_climbed > 0:
	#	unlock_next_rooms()
	#else:
	#	unlock_floor()


func create_map() -> void:
	for current_floor: Array in map_data:
		for room: MapRoom in current_floor:
			if room.next_rooms.size() > 0:
				print("Room at (", room.row, ", ", room.column, ") has ", room.next_rooms.size(), " next rooms")
				_spawn_room(room)
	
	# Boss room has no next room but we need to spawn it
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS-1][middle])

	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = get_viewport_rect().size.y / 2


func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.row == which_floor:
			map_room.set_available(true)

#
#func unlock_next_rooms() -> void:
#	for map_room: MapRoom in rooms.get_children():
#		if last_room.next_rooms.has(map_room.room):
#			map_room.available = true


func show_map() -> void:
	show()
	camera_2d.enabled = true


func hide_map() -> void:
	hide()
	camera_2d.enabled = false


func _spawn_room(room: MapRoom) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	print("Spawned room node:", new_map_room.position)
	new_map_room.position = room.position
	new_map_room.row = room.row
	new_map_room.column = room.column
	new_map_room.next_rooms = room.next_rooms
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)
	
	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: MapRoom) -> void:
	if room.next_rooms.is_empty():
		return
		
	for next: MapRoom in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		print("Line room node:", room.position)
		new_map_line.add_point(room.position)
		new_map_line.add_point(next.position)
		lines.add_child(new_map_line)


func _on_map_room_clicked(room: MapRoom) -> void:
	print("Room clicked:", room)
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false


func _on_map_room_selected(room: MapRoom) -> void:
	print("Room selected in map emit:", room)
	room._on_map_room_selected(self.room)
	last_room = room
	floors_climbed += 1
	#Events.map_exited.emit(room)
