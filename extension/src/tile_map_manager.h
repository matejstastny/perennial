#pragma once

#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/classes/tile_set.hpp>
#include <godot_cpp/classes/tile_set_atlas_source.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include "tile_registry.h"

namespace godot {

class TileMapManager : public TileMap {
	GDCLASS(TileMapManager, TileMap)

public:
	static const Vector2i TILE_SIZE;

	void _ready() override;

	void load_world(const Array &data);
	void set_tile_cell(Vector2i coords, int tile_type);
	int  get_tile_at(Vector2 world_pos) const;
	bool                  is_walkable_at(Vector2 world_pos) const;
	float                 get_speed_mod_at(Vector2 world_pos) const;
	Vector2i              world_to_tile_coords(Vector2 world_pos) const;
	Vector2               tile_to_world_center(Vector2i tile_coords) const;

protected:
	static void _bind_methods();

private:
	Array _tile_grid;

	Ref<TileSet> _build_tileset();
	static Ref<TileSetAtlasSource> _make_source(Color color, Vector2i size, bool solid);
};

} // namespace godot
