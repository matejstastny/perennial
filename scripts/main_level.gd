extends Node2D

@export var pause_menu : Node

var paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
