#include "game_world.h"

#include <godot_cpp/classes/camera2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

#include "world_generator.h"

using namespace godot;

void GameWorld::_ready() {
	_setup_world();
	_setup_player();
	_setup_camera();
}

void GameWorld::_setup_world() {
	_tile_map = memnew(TileMapManager);
	add_child(_tile_map);
	_world_data = WorldGenerator::generate(_world_width, _world_height, _world_seed);
	_tile_map->load_world(_world_data);
}

void GameWorld::_setup_player() {
	_player = memnew(Player);
	_player->set_tile_map(_tile_map);
	add_child(_player);
	_player->set_global_position(_find_spawn());
}

void GameWorld::_setup_camera() {
	Camera2D *cam = memnew(Camera2D);
	cam->set_zoom(Vector2(_camera_zoom, _camera_zoom));
	_player->add_child(cam);
}

Vector2 GameWorld::_find_spawn() const {
	int cx = _world_width  / 2;
	int cy = _world_height / 2;

	for (int radius = 0; radius < _world_width / 2; radius++) {
		for (int dy = -radius; dy <= radius; dy++) {
			for (int dx = -radius; dx <= radius; dx++) {
				if (Math::abs(dx) != radius && Math::abs(dy) != radius) {
					continue; // only walk the ring border
				}
				int tx = cx + dx;
				int ty = cy + dy;
				if (tx < 0 || ty < 0 || tx >= _world_width || ty >= _world_height) {
					continue;
				}
				Array row = _world_data[ty];
				if (TileRegistry::is_walkable((int)row[tx])) {
					return _tile_map->tile_to_world_center(Vector2i(tx, ty));
				}
			}
		}
	}
	return _tile_map->tile_to_world_center(Vector2i(cx, cy));
}

void GameWorld::set_world_width(int w)  { _world_width  = w; }
void GameWorld::set_world_height(int h) { _world_height = h; }
void GameWorld::set_world_seed(int s)   { _world_seed   = s; }
void GameWorld::set_camera_zoom(float z) { _camera_zoom = z; }

void GameWorld::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_world_width",  "width"),  &GameWorld::set_world_width);
	ClassDB::bind_method(D_METHOD("get_world_width"),            &GameWorld::get_world_width);
	ClassDB::bind_method(D_METHOD("set_world_height", "height"), &GameWorld::set_world_height);
	ClassDB::bind_method(D_METHOD("get_world_height"),           &GameWorld::get_world_height);
	ClassDB::bind_method(D_METHOD("set_world_seed",   "seed"),   &GameWorld::set_world_seed);
	ClassDB::bind_method(D_METHOD("get_world_seed"),             &GameWorld::get_world_seed);
	ClassDB::bind_method(D_METHOD("set_camera_zoom",  "zoom"),   &GameWorld::set_camera_zoom);
	ClassDB::bind_method(D_METHOD("get_camera_zoom"),            &GameWorld::get_camera_zoom);

	ADD_PROPERTY(PropertyInfo(Variant::INT,   "world_width"),  "set_world_width",  "get_world_width");
	ADD_PROPERTY(PropertyInfo(Variant::INT,   "world_height"), "set_world_height", "get_world_height");
	ADD_PROPERTY(PropertyInfo(Variant::INT,   "world_seed"),   "set_world_seed",   "get_world_seed");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "camera_zoom"),  "set_camera_zoom",  "get_camera_zoom");
}
