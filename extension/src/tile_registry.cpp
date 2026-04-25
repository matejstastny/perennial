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

bool TileRegistry::is_walkable(TileType tile_type) {
	return TILE_DATA[tile_type].walkable;
}

float TileRegistry::get_speed_mod(TileType tile_type) {
	return TILE_DATA[tile_type].speed_mod;
}

Color TileRegistry::get_color(TileType tile_type) {
	return TILE_DATA[tile_type].color;
}

String TileRegistry::get_tile_name(TileType tile_type) {
	return TILE_DATA[tile_type].name;
}

void TileRegistry::_bind_methods() {
	BIND_ENUM_CONSTANT(GRASS);
	BIND_ENUM_CONSTANT(DIRT);
	BIND_ENUM_CONSTANT(STONE);
	BIND_ENUM_CONSTANT(WATER);
	BIND_ENUM_CONSTANT(SAND);
	BIND_ENUM_CONSTANT(FOREST);

	ClassDB::bind_static_method("TileRegistry", D_METHOD("is_walkable", "tile_type"),   &TileRegistry::is_walkable);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_speed_mod", "tile_type"), &TileRegistry::get_speed_mod);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_color", "tile_type"),     &TileRegistry::get_color);
	ClassDB::bind_static_method("TileRegistry", D_METHOD("get_tile_name", "tile_type"), &TileRegistry::get_tile_name);
}
