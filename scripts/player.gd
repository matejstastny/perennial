class_name Player
extends CharacterBody2D

const BASE_SPEED := 200.0

var tile_map: TileMapManager


func _ready() -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = 6.0
	shape.height = 12.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	var rect := ColorRect.new()
	rect.color = Color.RED
	rect.size = Vector2(12.0, 18.0)
	rect.position = Vector2(-6.0, -9.0)
	add_child(rect)


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed_mod := tile_map.get_speed_mod_at(global_position) if tile_map else 1.0
	velocity = dir * BASE_SPEED * speed_mod
	move_and_slide()
