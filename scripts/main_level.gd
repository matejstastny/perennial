extends Node2D

@onready var pause_menu = $PauseMenu

var paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		pauseMenu(!paused)

func pauseMenu(xpause):
	if xpause:
		paused = true
		pause_menu.show()
		get_tree().paused = true
		Engine.time_scale = 1
	else:
		paused = false
		pause_menu.hide()
		get_tree().paused = false
		Engine.time_scale = 0