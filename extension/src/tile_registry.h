#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/type_info.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class TileRegistry : public Object {
	GDCLASS(TileRegistry, Object)

public:
	enum TileType {
		GRASS  = 0,
		DIRT   = 1,
		STONE  = 2,
		WATER  = 3,
		SAND   = 4,
		FOREST = 5,
		TILE_TYPE_MAX,
	};

	static bool   is_walkable(TileType tile_type);
	static float  get_speed_mod(TileType tile_type);
	static Color  get_color(TileType tile_type);
	static String get_tile_name(TileType tile_type);

protected:
	static void _bind_methods();
};

} // namespace godot

VARIANT_ENUM_CAST(godot::TileRegistry::TileType)
