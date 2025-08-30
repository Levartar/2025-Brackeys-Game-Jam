extends Control

func _resized():
	var win_size = min(size.x, size.y)
	custom_minimum_size = Vector2(win_size, win_size)
	#rect_position = (get_viewport_rect().size - Vector2(size, size)) / 2

func _ready():
	connect("resized", Callable(self, "_resized"))
	_resized()



func _on_restart_pressed() -> void:
	GameManager.map_seed = randi()
	get_tree().reload_current_scene()


func _on_pause_button_pressed() -> void:
	print("Pause button pressed")
	get_tree().paused = true


func _on_bottom_button_pressed() -> void:
	get_tree().paused = false
