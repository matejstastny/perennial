#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class TileRegistry : public Object {
	GDCLASS(TileRegistry, Object)

public:
	// Exposed as integer constants to GDScript (TileRegistry.GRASS etc.)
	enum TileType {
		GRASS  = 0,
		DIRT   = 1,
		STONE  = 2,
		WATER  = 3,
		SAND   = 4,
		FOREST = 5,
		TILE_TYPE_MAX,
	};

	// Bound methods take int so the variant system doesn't need VARIANT_ENUM_CAST.
	// Callers in C++ still pass TileType values; they convert implicitly.
	static bool   is_walkable(int tile_type);
	static float  get_speed_mod(int tile_type);
	static Color  get_color(int tile_type);
	static String get_tile_name(int tile_type);

protected:
	static void _bind_methods();
};

} // namespace godot
