import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stts/stts.dart';

import 'support/platform.dart';
import 'support/stream_recorder.dart';

// Recognition runs without speech input, so it may also end by itself with
// "no match" or "speech timeout" errors. Tests only check the lifecycle.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Stt stt;
  late StreamRecorder<SttState> states;

  // Returns false and skips the test when STT can't be used on this device.
  Future<bool> sttReady() async {
    if (!await stt.isSupported()) {
      return skipTest('STT is not supported.');
    }

    // Permission can't be granted from a test. It must be granted beforehand.
    final granted = await stt.hasPermission().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
    if (!granted) {
      return skipTest('Microphone/speech permission is not granted.');
    }
    return true;
  }

  setUp(() {
    stt = Stt();
    states = StreamRecorder(stt.onStateChanged);
  });

  tearDown(() async {
    await stt.stop();
    await stt.dispose();
    await states.cancel();
  });

  testWidgets('lists languages', (_) async {
    if (!await sttReady()) return;

    expect(await stt.getLanguages(), isNotEmpty);
    expect(await stt.getLanguage(), isNotEmpty);
  });

  testWidgets('sets language', (_) async {
    if (!await sttReady()) return;

    final language = (await stt.getLanguages()).first;
    await stt.setLanguage(language);

    expect((await stt.getLanguage()).toLowerCase(), language.toLowerCase());
  });

  testWidgets('normalizes language tag', (_) async {
    if (!await sttReady()) return;

    await stt.setLanguage('en_us');
    expect(await stt.getLanguage(), 'en-US');
  }, skip: !isAndroid && !isIOS);

  testWidgets('start then stop', (_) async {
    if (!await sttReady()) return;

    await stt.start();
    final started = await states.waitFor(SttState.start);

    await stt.stop();
    await states.waitFor(
      SttState.stop,
      from: started,
      timeout: const Duration(seconds: 5),
    );
  });

  testWidgets('quick stop/start cycle reports both sessions', (_) async {
    if (!await sttReady()) return;

    await stt.start();
    final firstStart = await states.waitFor(SttState.start);

    await stt.stop();
    await stt.start();

    final firstStop = await states.waitFor(SttState.stop, from: firstStart);
    final secondStart = await states.waitFor(SttState.start, from: firstStop);

    await stt.stop();
    await states.waitFor(
      SttState.stop,
      from: secondStart,
      timeout: const Duration(seconds: 5),
    );
  });

  testWidgets('sets language after a session', (_) async {
    if (!await sttReady()) return;

    await stt.start();
    final started = await states.waitFor(SttState.start);
    await stt.stop();
    final stopped = await states.waitFor(SttState.stop, from: started);

    final current = await stt.getLanguage();
    final languages = await stt.getLanguages();
    final language = languages.firstWhere(
      (l) => l.toLowerCase() != current.toLowerCase(),
      orElse: () => current,
    );
    await stt.setLanguage(language);
    expect((await stt.getLanguage()).toLowerCase(), language.toLowerCase());

    await stt.start();
    final restarted = await states.waitFor(SttState.start, from: stopped);
    await stt.stop();
    await states.waitFor(
      SttState.stop,
      from: restarted,
      timeout: const Duration(seconds: 5),
    );
  });

  testWidgets('start while listening is ignored', (_) async {
    if (!await sttReady()) return;

    await stt.start();
    final started = await states.waitFor(SttState.start);

    await stt.start();
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(states.events.sublist(started + 1), isEmpty);
    expect(states.errors, isEmpty);
  }, skip: !isWindows && !isIOS);

  testWidgets('stop without session', (_) async {
    if (!await sttReady()) return;

    await stt.stop();

    final after = await states.eventsDuring(const Duration(seconds: 1));
    expect(after, isNot(contains(SttState.start)));
  });

  group('Android', () {
    late int ringerMode;

    // Returns false and skips the test when the ringer mode can't be changed.
    Future<bool> setRingerMode(int mode) async {
      try {
        await TestHooks.setRingerMode(mode);
      } on PlatformException catch (_) {}

      if (await TestHooks.getRingerMode() == mode) return true;
      return skipTest(
        'Ringer mode can\'t be set (Do Not Disturb, or vibrate without vibrator).',
      );
    }

    setUp(() async {
      ringerMode = await TestHooks.getRingerMode();
    });

    tearDown(() async {
      await stt.android!.muteSystemSounds(false);
      try {
        await TestHooks.setRingerMode(ringerMode);
      } on PlatformException catch (_) {}
    });

    testWidgets('mute system sounds restores ringer mode', (_) async {
      if (!await sttReady()) return;
      if (!await setRingerMode(TestHooks.ringerModeNormal)) return;

      await stt.android!.muteSystemSounds(true);

      await stt.start();
      final started = await states.waitFor(SttState.start);
      // Without vibrator, muting would turn to silent (Do Not Disturb). Ringer is left as is.
      expect(
        await TestHooks.getRingerMode(),
        await TestHooks.hasVibrator()
            ? TestHooks.ringerModeVibrate
            : TestHooks.ringerModeNormal,
      );

      await stt.stop();
      await states.waitFor(
        SttState.stop,
        from: started,
        timeout: const Duration(seconds: 5),
      );
      expect(await TestHooks.getRingerMode(), TestHooks.ringerModeNormal);
    });

    testWidgets('stop without session keeps ringer mode', (_) async {
      if (!await sttReady()) return;
      if (!await setRingerMode(TestHooks.ringerModeVibrate)) return;

      await stt.android!.muteSystemSounds(true);

      await stt.stop();
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(await TestHooks.getRingerMode(), TestHooks.ringerModeVibrate);
    });

    testWidgets('download model end arrives after the call returns', (_) async {
      if (!await sttReady()) return;

      // API 34+ may show the download UI instead.
      if (await TestHooks.getSdkInt() >= 34) {
        skipTest('Requires API < 34.');
        return;
      }

      final order = <String>[];
      final ended = Completer<int?>();
      stt.android!.onDownloadModelEnd((language, errCode) {
        order.add('end');
        ended.complete(errCode);
      });

      await stt.android!.downloadModel('en-US');
      order.add('returned');

      expect(await ended.future.timeout(const Duration(seconds: 5)), isNotNull);
      expect(order, ['returned', 'end']);

      stt.android!.onDownloadModelEnd(null);
    });
  }, skip: !isAndroid);
}
