extends Control

var pause = false

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
	if not pause:
		pause = true
		for child in get_children():
				for childrens in child.get_children():
					childrens.set_process(false)
					childrens.set_physics_process(false)
					childrens.set_process_input(false)
					childrens.set_process_unhandled_input(false)
					childrens.set_process_unhandled_key_input(false)
	else:
		pause = false
		for child in get_children():
				for childrens in child.get_children():
					childrens.set_process(true)
					childrens.set_physics_process(true)
					childrens.set_process_input(true)
					childrens.set_process_unhandled_input(true)
					childrens.set_process_unhandled_key_input(true)
	

func _on_bottom_button_pressed() -> void:
	get_tree().paused = false
