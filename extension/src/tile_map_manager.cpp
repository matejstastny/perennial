#include "tile_map_manager.h"

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/tile_data.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

using namespace godot;

const Vector2i TileMapManager::TILE_SIZE = Vector2i(32, 32);

void TileMapManager::_ready() {
	set_tileset(_build_tileset());
}

void TileMapManager::load_world(const Array &data) {
	_tile_grid = data;
	for (int y = 0; y < data.size(); y++) {
		Array row = data[y];
		for (int x = 0; x < row.size(); x++) {
			set_tile_cell(Vector2i(x, y), (int)row[x]);
		}
	}
}

void TileMapManager::set_tile_cell(Vector2i coords, int tile_type) {
	set_cell(0, coords, tile_type, Vector2i(0, 0));
}

int TileMapManager::get_tile_at(Vector2 world_pos) const {
	Vector2i coords = local_to_map(to_local(world_pos));
	int y = coords.y;
	int x = coords.x;
	if (y >= 0 && y < _tile_grid.size()) {
		Array row = _tile_grid[y];
		if (x >= 0 && x < row.size()) {
			return (int)row[x];
		}
	}
	return TileRegistry::GRASS;
}

bool TileMapManager::is_walkable_at(Vector2 world_pos) const {
	return TileRegistry::is_walkable(get_tile_at(world_pos));
}

float TileMapManager::get_speed_mod_at(Vector2 world_pos) const {
	return TileRegistry::get_speed_mod(get_tile_at(world_pos));
}

Vector2i TileMapManager::world_to_tile_coords(Vector2 world_pos) const {
	return local_to_map(to_local(world_pos));
}

Vector2 TileMapManager::tile_to_world_center(Vector2i tile_coords) const {
	return to_global(map_to_local(tile_coords));
}

Ref<TileSet> TileMapManager::_build_tileset() {
	Ref<TileSet> tileset;
	tileset.instantiate();
	tileset->set_tile_size(TILE_SIZE);
	tileset->add_physics_layer();

	for (int i = 0; i < TileRegistry::TILE_TYPE_MAX; i++) {
		Color color = TileRegistry::get_color(i);
		bool solid = !TileRegistry::is_walkable(i);
		Ref<TileSetAtlasSource> source = _make_source(color, TILE_SIZE, solid);
		tileset->add_source(source, i);
	}
	return tileset;
}

Ref<TileSetAtlasSource> TileMapManager::_make_source(Color color, Vector2i size, bool solid) {
	Ref<Image> image = Image::create(size.x, size.y, false, Image::FORMAT_RGBA8);
	image->fill(color);

	Color border = color.darkened(0.25f);
	for (int i = 0; i < size.x; i++) {
		image->set_pixel(i, 0,          border);
		image->set_pixel(i, size.y - 1, border);
	}
	for (int i = 0; i < size.y; i++) {
		image->set_pixel(0,          i, border);
		image->set_pixel(size.x - 1, i, border);
	}

	Ref<ImageTexture> texture = ImageTexture::create_from_image(image);

	Ref<TileSetAtlasSource> source;
	source.instantiate();
	source->set_texture(texture);
	source->set_texture_region_size(size);
	source->create_tile(Vector2i(0, 0));

	if (solid) {
		TileData *tile_data = source->get_tile_data(Vector2i(0, 0), 0);
		Vector2 half = Vector2((float)size.x, (float)size.y) * 0.5f;
		tile_data->add_collision_polygon(0);
		PackedVector2Array polygon;
		polygon.push_back(Vector2(-half.x, -half.y));
		polygon.push_back(Vector2( half.x, -half.y));
		polygon.push_back(Vector2( half.x,  half.y));
		polygon.push_back(Vector2(-half.x,  half.y));
		tile_data->set_collision_polygon_points(0, 0, polygon);
	}

	return source;
}

void TileMapManager::_bind_methods() {
	ClassDB::bind_method(D_METHOD("load_world", "data"),                    &TileMapManager::load_world);
	ClassDB::bind_method(D_METHOD("set_tile_cell", "coords", "tile_type"),  &TileMapManager::set_tile_cell);
	ClassDB::bind_method(D_METHOD("get_tile_at", "world_pos"),              &TileMapManager::get_tile_at);
	ClassDB::bind_method(D_METHOD("is_walkable_at", "world_pos"),           &TileMapManager::is_walkable_at);
	ClassDB::bind_method(D_METHOD("get_speed_mod_at", "world_pos"),         &TileMapManager::get_speed_mod_at);
	ClassDB::bind_method(D_METHOD("world_to_tile_coords", "world_pos"),     &TileMapManager::world_to_tile_coords);
	ClassDB::bind_method(D_METHOD("tile_to_world_center", "tile_coords"),   &TileMapManager::tile_to_world_center);
}
