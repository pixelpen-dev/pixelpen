#include "register_types.h"

#include "PixelPenCPP.h"
#include "PixelPenImage.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_pixelpen(ModuleInitializationLevel p_level)
{
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_CLASS(PixelPenCPP);
	GDREGISTER_CLASS(PixelPenImage);
}

void uninitialize_pixelpen(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	
}

extern "C"
{
	// Initialization
	GDExtensionBool GDE_EXPORT pixelpen_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address, 
		GDExtensionClassLibraryPtr p_library, 
		GDExtensionInitialization *r_initialization)
	{
		godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_pixelpen);
		init_obj.register_terminator(uninitialize_pixelpen);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SERVERS);

		return init_obj.init();
	}
}