#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/array.hpp>

#include "tile_registry.h"

namespace godot {

class WorldGenerator : public Object {
	GDCLASS(WorldGenerator, Object)

public:
	static Array generate(int width, int height, int seed);

protected:
	static void _bind_methods();

private:
	static TileRegistry::TileType classify(float elevation, float moisture);
};

} // namespace godot
