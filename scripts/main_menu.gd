extends Control

func _on_start_button_pressed():
	print("Start Game button clicked! Ready to load the first level.")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_button_pressed():
	print("Quit button clicked. Closing the game.")
	get_tree().quit()
