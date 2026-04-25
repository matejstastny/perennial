#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "game_world.h"
#include "player.h"
#include "tile_map_manager.h"
#include "tile_registry.h"
#include "world_generator.h"

using namespace godot;

void initialize_perennial(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	ClassDB::register_class<TileRegistry>();
	ClassDB::register_class<WorldGenerator>();
	ClassDB::register_class<TileMapManager>();
	ClassDB::register_class<Player>();
	ClassDB::register_class<GameWorld>();
}

void uninitialize_perennial(ModuleInitializationLevel p_level) {
	(void)p_level;
}

extern "C" {

GDExtensionBool GDE_EXPORT perennial_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_perennial);
	init_obj.register_terminator(uninitialize_perennial);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}

} // extern "C"
