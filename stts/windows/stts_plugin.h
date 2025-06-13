#ifndef FLUTTER_PLUGIN_STTS_PLUGIN_H_
#define FLUTTER_PLUGIN_STTS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/encodable_value.h>

#include <memory>
#include "stt/stt.h"
#include "tts/tts.h"
#include "tts/tts_options.h"

namespace stts {

class SttsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SttsPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~SttsPlugin();

  // Disallow copy and assign.
  SttsPlugin(const SttsPlugin&) = delete;
  SttsPlugin& operator=(const SttsPlugin&) = delete;

  // STT
  void SttHandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // TTS
  void TtsHandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

private:
    std::unique_ptr<Stt> mStt;
    std::unique_ptr<Tts> mTts;

    std::string ttsVoiceGenderToString(TtsVoiceGender gender);
    std::unique_ptr<TtsOptions> GetTtsOptions(const EncodableMap* args);

    std::string GetErrorMessage(HRESULT hr);
};

}  // namespace stts

#endif  // FLUTTER_PLUGIN_STTS_PLUGIN_H_
