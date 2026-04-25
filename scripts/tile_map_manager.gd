class_name TileMapManager
extends TileMapLayer

const TILE_SIZE := Vector2i(32, 32)

var _world_data: Array = []


func load_world(data: Array) -> void:
	_world_data = data
	tile_set = _build_tileset()

	for y in data.size():
		for x in data[y].size():
			set_cell(Vector2i(x, y), data[y][x], Vector2i(0, 0))


func get_tile_at(world_pos: Vector2) -> TileRegistry.TileType:
	var coords := world_to_tile(world_pos)
	if _world_data.is_empty():
		return TileRegistry.TileType.GRASS
	var row: Array = _world_data[clampi(coords.y, 0, _world_data.size() - 1)]
	return row[clampi(coords.x, 0, row.size() - 1)]


func is_walkable_at(world_pos: Vector2) -> bool:
	return TileRegistry.is_walkable(get_tile_at(world_pos))


func get_speed_mod_at(world_pos: Vector2) -> float:
	return TileRegistry.get_speed_mod(get_tile_at(world_pos))


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))


func tile_to_world_center(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))


# ── TileSet construction ───────────────────────────────────────────────────────

func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = TILE_SIZE
	ts.add_physics_layer(0)

	for tile_type in TileRegistry.TileType.values():
		var source := TileSetAtlasSource.new()
		source.texture = _make_texture(TileRegistry.get_color(tile_type))
		source.texture_region_size = TILE_SIZE
		source.create_tile(Vector2i(0, 0))

		if not TileRegistry.is_walkable(tile_type):
			var td: TileData = source.get_tile_data(Vector2i(0, 0), 0)
			td.set_collision_polygons_count(0, 1)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(0, 0), Vector2(32, 0), Vector2(32, 32), Vector2(0, 32),
			]))

		ts.add_source(source, tile_type)

	return ts


func _make_texture(color: Color) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var border := Color(color.r * 0.70, color.g * 0.70, color.b * 0.70, color.a)
	for i in 32:
		img.set_pixel(i, 0, border)
		img.set_pixel(i, 31, border)
		img.set_pixel(0, i, border)
		img.set_pixel(31, i, border)
	return ImageTexture.create_from_image(img)
