#include "world_generator.h"

#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

Array WorldGenerator::generate(int width, int height, int seed) {
  godot::Ref<FastNoiseLite> elevation;
  elevation.instantiate();
  elevation->set_seed(seed);
  elevation->set_frequency(0.04f);
  elevation->set_noise_type(FastNoiseLite::TYPE_SIMPLEX_SMOOTH);

  godot::Ref<FastNoiseLite> moisture;
  moisture.instantiate();
  moisture->set_seed(seed + 1);
  moisture->set_frequency(0.06f);
  moisture->set_noise_type(FastNoiseLite::TYPE_SIMPLEX_SMOOTH);

  Array data;
  data.resize(height);
  for (int y = 0; y < height; y++) {
    Array row;
    row.resize(width);
    for (int x = 0; x < width; x++) {
      float e = elevation->get_noise_2d((float)x, (float)y);
      float m = moisture->get_noise_2d((float)x, (float)y);
      row[x] = (int)classify(e, m);
    }
    data[y] = row;
  }
  return data;
}

TileRegistry::TileType WorldGenerator::classify(float e, float m) {
  if (e < -0.25f) return TileRegistry::WATER;
  if (e < -0.05f) return TileRegistry::SAND;
  if (e < 0.40f) {
    if (m > 0.20f) return TileRegistry::FOREST;
    if (m < -0.20f) return TileRegistry::DIRT;
    return TileRegistry::GRASS;
  }
  return TileRegistry::STONE;
}

void WorldGenerator::_bind_methods() {
  ClassDB::bind_static_method("WorldGenerator",
                              D_METHOD("generate", "width", "height", "seed"),
                              &WorldGenerator::generate);
}
