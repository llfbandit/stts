#include "include/stts/stts_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "stts_plugin.h"

void SttsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  stts::SttsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
