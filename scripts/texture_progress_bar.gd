extends TextureProgressBar

var terrain: Node = null

func _ready():
	call_deferred("_get_terrain")

func _get_terrain():
	var flight_sim = get_tree().get_root().get_node("Game/CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/MapContainer/Flight Sim")
	if flight_sim:
		terrain = flight_sim.get_node("Terrain")
		if terrain == null:
			print("Terrain node not found!")
	else:
		print("Flight Sim node not found!")

func update_progress(val: float) -> void:
	self.value += val
