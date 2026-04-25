#pragma once

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include "player.h"
#include "tile_map_manager.h"

namespace godot {

class GameWorld : public Node2D {
	GDCLASS(GameWorld, Node2D)

public:
	void _ready() override;

	void  set_world_width(int w);
	int   get_world_width() const  { return _world_width; }
	void  set_world_height(int h);
	int   get_world_height() const { return _world_height; }
	void  set_world_seed(int s);
	int   get_world_seed() const   { return _world_seed; }
	void  set_camera_zoom(float z);
	float get_camera_zoom() const  { return _camera_zoom; }

protected:
	static void _bind_methods();

private:
	int   _world_width  = 80;
	int   _world_height = 60;
	int   _world_seed   = 42;
	float _camera_zoom  = 2.5f;

	TileMapManager *_tile_map   = nullptr;
	Player         *_player     = nullptr;
	Array           _world_data;

	void    _setup_world();
	void    _setup_player();
	void    _setup_camera();
	Vector2 _find_spawn() const;
};

} // namespace godot
