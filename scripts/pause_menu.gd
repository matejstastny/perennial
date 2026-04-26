extends Control

@export var main: Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed():
	pauseMenu(false)

func _on_quit_button_pressed():
	get_tree().quit()

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu(true)

func pauseMenu(xpause):
	if xpause:
		#paused = true
		#pause_menu.show()
		show()
		get_tree().paused = true
		#Engine.time_scale = 1
	else:
		#paused = false
		#pause_menu.hide()
		hide()
		get_tree().paused = false
		#Engine.time_scale = 0
