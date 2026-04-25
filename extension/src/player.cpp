#include "player.h"

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/collision_shape2d.hpp>
#include <godot_cpp/classes/color_rect.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>

using namespace godot;

void Player::_ready() {
	_setup_collision();
	_setup_visual();
}

void Player::_physics_process(double /*delta*/) {
	Vector2 direction = Input::get_singleton()->get_vector("ui_left", "ui_right", "ui_up", "ui_down");
	if (direction == Vector2()) {
		set_velocity(Vector2());
		return;
	}
	float speed_mod = _tile_map ? _tile_map->get_speed_mod_at(get_global_position()) : 1.0f;
	set_velocity(direction * BASE_SPEED * speed_mod);
	move_and_slide();
}

void Player::set_tile_map(TileMapManager *tile_map) {
	_tile_map = tile_map;
}

TileMapManager *Player::get_tile_map() const {
	return _tile_map;
}

void Player::_setup_collision() {
	CollisionShape2D *col = memnew(CollisionShape2D);
	Ref<CapsuleShape2D> shape;
	shape.instantiate();
	shape->set_radius(6.0f);
	shape->set_height(12.0f);
	col->set_shape(shape);
	add_child(col);
}

void Player::_setup_visual() {
	ColorRect *rect = memnew(ColorRect);
	rect->set_color(Color(0.9f, 0.25f, 0.25f));
	rect->set_size(Vector2(12.0f, 18.0f));
	rect->set_position(Vector2(-6.0f, -9.0f));
	add_child(rect);
}

void Player::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_tile_map", "tile_map"), &Player::set_tile_map);
	ClassDB::bind_method(D_METHOD("get_tile_map"),             &Player::get_tile_map);
	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "tile_map", PROPERTY_HINT_NODE_TYPE, "TileMapManager"),
	             "set_tile_map", "get_tile_map");
}
