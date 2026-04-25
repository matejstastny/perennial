class_name WorldGenerator
extends RefCounted

## Returns a 2D array [y][x] of TileRegistry.TileType values.
static func generate(width: int, height: int, world_seed: int) -> Array:
	var elevation := FastNoiseLite.new()
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation.seed = world_seed
	elevation.frequency = 0.04

	var moisture := FastNoiseLite.new()
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture.seed = world_seed + 1
	moisture.frequency = 0.06

	var data: Array = []
	data.resize(height)
	for y in height:
		var row: Array = []
		row.resize(width)
		for x in width:
			var e: float = elevation.get_noise_2d(x, y)
			var m: float = moisture.get_noise_2d(x, y)
			row[x] = _classify(e, m)
		data[y] = row

	return data


static func _classify(e: float, m: float) -> TileRegistry.TileType:
	if e < -0.25:
		return TileRegistry.TileType.WATER
	if e < -0.05:
		return TileRegistry.TileType.SAND
	if e < 0.40:
		if m > 0.20:
			return TileRegistry.TileType.FOREST
		if m < -0.20:
			return TileRegistry.TileType.DIRT
		return TileRegistry.TileType.GRASS
	return TileRegistry.TileType.STONE
