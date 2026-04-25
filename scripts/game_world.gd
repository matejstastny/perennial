class_name GameWorld
extends Node2D

@export var world_width: int = 80
@export var world_height: int = 60
@export var world_seed: int = 42
@export var camera_zoom: float = 2.5

var _tile_map: TileMapManager
var _world_data: Array = []


func _ready() -> void:
	_setup_world()
	_setup_player()


func _setup_world() -> void:
	_world_data = WorldGenerator.generate(world_width, world_height, world_seed)

	_tile_map = TileMapManager.new()
	add_child(_tile_map)
	_tile_map.load_world(_world_data)


func _setup_player() -> void:
	var spawn_tile := _find_spawn()
	var spawn_pos := _tile_map.tile_to_world_center(spawn_tile)

	var player := Player.new()
	player.tile_map = _tile_map
	player.global_position = spawn_pos
	add_child(player)

	_setup_camera(player)


func _setup_camera(player: Player) -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(camera_zoom, camera_zoom)
	player.add_child(cam)


func _find_spawn() -> Vector2i:
	var cx := world_width / 2
	var cy := world_height / 2
	var max_r := maxi(world_width, world_height)

	for radius in range(0, max_r):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var tx := cx + dx
				var ty := cy + dy
				if tx < 0 or tx >= world_width or ty < 0 or ty >= world_height:
					continue
				if TileRegistry.is_walkable(_world_data[ty][tx]):
					return Vector2i(tx, ty)

	return Vector2i(cx, cy)
