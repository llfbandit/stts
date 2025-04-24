import 'stt_method_channel_mixin.dart';
import 'stt_platform_interface.dart';

class SttPlatform extends SttPlatformInterface
    with SttMethodChannel, SttEventChannel {
  SttPlatform();
}
