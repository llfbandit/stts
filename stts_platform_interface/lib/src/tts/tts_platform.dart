import 'tts_method_channel_mixin.dart';
import 'tts_platform_interface.dart';

class TtsPlatform extends TtsPlatformInterface
    with TtsMethodChannel, TtsEventChannel {
  TtsPlatform();
}
