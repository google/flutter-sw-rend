//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <sw_rend/sw_rend_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) sw_rend_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SwRendPlugin");
  sw_rend_plugin_register_with_registrar(sw_rend_registrar);
}
