class_name TileRegistry
extends RefCounted

enum TileType { GRASS = 0, DIRT, STONE, WATER, SAND, FOREST }

const _DATA := [
	# walkable, speed_mod, color,                        name
	[true,  1.00, Color(0.42, 0.69, 0.24), "Grass"],   # GRASS
	[true,  0.85, Color(0.60, 0.40, 0.20), "Dirt"],    # DIRT
	[true,  1.00, Color(0.55, 0.55, 0.55), "Stone"],   # STONE
	[false, 0.00, Color(0.20, 0.45, 0.80), "Water"],   # WATER
	[true,  0.80, Color(0.85, 0.78, 0.45), "Sand"],    # SAND
	[true,  0.65, Color(0.18, 0.42, 0.12), "Forest"],  # FOREST
]

static func is_walkable(t: TileType) -> bool:
	return TileRegistry._DATA[t][0]

static func get_speed_mod(t: TileType) -> float:
	return TileRegistry._DATA[t][1]

static func get_color(t: TileType) -> Color:
	return TileRegistry._DATA[t][2]

static func get_tile_name(t: TileType) -> String:
	return TileRegistry._DATA[t][3]
