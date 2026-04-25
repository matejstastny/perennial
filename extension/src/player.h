#pragma once

#include <godot_cpp/classes/character_body2d.hpp>

#include "tile_map_manager.h"

namespace godot {

class Player : public CharacterBody2D {
	GDCLASS(Player, CharacterBody2D)

public:
	static constexpr float BASE_SPEED = 200.0f;

	void _ready() override;
	void _physics_process(double delta) override;

	void             set_tile_map(TileMapManager *tile_map);
	TileMapManager  *get_tile_map() const;

protected:
	static void _bind_methods();

private:
	TileMapManager *_tile_map = nullptr;

	void _setup_collision();
	void _setup_visual();
};

} // namespace godot
