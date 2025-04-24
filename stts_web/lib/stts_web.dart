import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:stts_platform_interface/stts_platform_interface.dart';
import 'package:stts_web/src/stt.dart';
import 'package:stts_web/src/tts.dart';

class SttsWeb {
  static void registerWith(Registrar registrar) {
    SttPlatformInterface.instance = Stt();
    TtsPlatformInterface.instance = Tts();
  }
}
