extends Control

@export var main: Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed() -> void:
	main.pauseMenu(false)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
