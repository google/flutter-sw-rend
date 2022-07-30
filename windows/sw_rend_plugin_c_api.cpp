#include "include/sw_rend/sw_rend_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "sw_rend_plugin.h"

void SwRendPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  sw_rend::SwRendPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
