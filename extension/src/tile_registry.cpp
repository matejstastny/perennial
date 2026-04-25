#include "tile_registry.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

struct TileProperties {
	const char *name;
	bool        walkable;
	float       speed_mod;
	Color       color;
};

static const TileProperties TILE_DATA[TileRegistry::TILE_TYPE_MAX] = {
	/* GRASS  */ { "Grass",  true,  1.00f, Color(0.35f, 0.72f, 0.25f) },
	/* DIRT   */ { "Dirt",   true,  0.85f, Color(0.60f, 0.42f, 0.22f) },
	/* STONE  */ { "Stone",  true,  1.00f, Color(0.52f, 0.52f, 0.52f) },
	/* WATER  */ { "Water",  false, 0.00f, Color(0.15f, 0.45f, 0.90f) },
	/* SAND   */ { "Sand",   true,  0.80f, Color(0.92f, 0.82f, 0.55f) },
	/* FOREST */ { "Forest", true,  0.65f, Color(0.12f, 0.48f, 0.12f) },
};

bool TileRegistry::is_walkable(int tile_type) {
	return TILE_DATA[tile_type].walkable;
}

float TileRegistry::get_speed_mod(int tile_type) {
	return TILE_DATA[tile_type].speed_mod;
}

Color TileRegistry::get_color(int tile_type) {
	return TILE_DATA[tile_type].color;
}

String TileRegistry::get_tile_name(int tile_type) {
	return TILE_DATA[tile_type].name;
}

void TileRegistry::_bind_methods() {
	// Register enum values as plain integer constants grouped under "TileType".
	// bind_integer_constant doesn't require VARIANT_ENUM_CAST.
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "GRASS",  GRASS);
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "DIRT",   DIRT);
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "STONE",  STONE);
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "WATER",  WATER);
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "SAND",   SAND);
	ClassDB::bind_integer_constant(get_class_static(), "TileType", "FOREST", FOREST);

	ClassDB::bind_static_method("TileRegistry", D_METHOD("is_walkable",  "tile_type"), &TileRegistry::is_walkable);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_speed_mod","tile_type"), &TileRegistry::get_speed_mod);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_color",    "tile_type"), &TileRegistry::get_color);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_tile_name","tile_type"), &TileRegistry::get_tile_name);
}
