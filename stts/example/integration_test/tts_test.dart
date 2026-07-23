import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stts/stts.dart';

import 'support/platform.dart';
import 'support/stream_recorder.dart';

const _shortText = 'Hello.';
const _longText =
    'This sentence is long enough to be paused, resumed and '
    'stopped while it is being spoken by the text to speech engine.';
const _speakTimeout = Duration(seconds: 30);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Tts tts;
  late StreamRecorder<TtsState> states;
  var ready = false;

  // Returns false and skips the test when TTS can't be used on this device.
  Future<bool> ttsReady() async {
    if (!await tts.isSupported()) {
      return skipTest('TTS is not supported.');
    }
    if ((await tts.getVoices()).isEmpty) {
      return skipTest('No TTS voice available.');
    }
    return ready = true;
  }

  // Stop must mean silence. States alone can't tell, e.g. a Start of replayed
  // speech is deduplicated when already started.
  Future<void> expectNoAudio() async {
    if (!isAndroid) return;

    // Let the audio tail end.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (var i = 0; i < 6; i++) {
      expect(
        await TestHooks.isMusicActive(),
        isFalse,
        reason: 'Audio still playing after stop',
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  setUp(() {
    ready = false;
    tts = Tts();
    states = StreamRecorder(tts.onStateChanged);
  });

  tearDown(() async {
    // Each test ends on Stop.
    await expectNoAudio();

    await tts.stop();
    await tts.dispose();
    await states.cancel();

    // An unsupported engine reports its initialisation error.
    if (ready) {
      expect(states.errors, isEmpty, reason: 'Unexpected TTS errors');
    }
  });

  testWidgets('lists languages and voices', (_) async {
    if (!await ttsReady()) return;

    final languages = await tts.getLanguages();
    expect(languages, isNotEmpty);

    final voices = await tts.getVoices();
    expect(voices, isNotEmpty);

    final language = voices.first.language;
    expect(await tts.getVoicesByLanguage(language), isNotEmpty);
  });

  testWidgets('sets language', (_) async {
    if (!await ttsReady()) return;

    final language = (await tts.getVoices()).first.language;
    await tts.setLanguage(language);

    expect((await tts.getLanguage()).toLowerCase(), language.toLowerCase());
  });

  testWidgets('voices have unique ids', (_) async {
    if (!await ttsReady()) return;

    final ids = (await tts.getVoices()).map((v) => v.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  // One installed voice per language, a few languages at most.
  Future<List<TtsVoice>> voicePerLanguage() async {
    final voices = <String, TtsVoice>{};
    for (final voice in await tts.getVoices()) {
      if (voice.languageInstalled && !voice.networkRequired) {
        voices.putIfAbsent(voice.language, () => voice);
      }
    }
    return voices.values.take(5).toList();
  }

  testWidgets('sets each language', (_) async {
    if (!await ttsReady()) return;

    for (final voice in await voicePerLanguage()) {
      await tts.setLanguage(voice.language);
      expect(
        (await tts.getLanguage()).toLowerCase(),
        voice.language.toLowerCase(),
      );
    }
  });

  testWidgets('sets each voice', (_) async {
    if (!await ttsReady()) return;

    for (final voice in await voicePerLanguage()) {
      await tts.setVoice(voice.id);
      expect(
        (await tts.getLanguage()).toLowerCase(),
        voice.language.toLowerCase(),
        reason: 'Voice ${voice.name} not selected',
      );
    }
  });

  testWidgets('normalizes language tag', (_) async {
    if (!await ttsReady()) return;

    final language = (await tts.getVoices()).first.language;
    await tts.setLanguage(language.replaceAll('-', '_').toLowerCase());

    expect(await tts.getLanguage(), language);
    expect(await tts.getVoicesByLanguage(language.toLowerCase()), isNotEmpty);
  }, skip: !isAndroid);

  testWidgets('speaks: start then stop', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_shortText);

    final started = await states.waitFor(TtsState.start);
    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
  });

  testWidgets('add mode: stops once after all utterances', (_) async {
    if (!await ttsReady()) return;

    await tts.start('One.');
    await tts.start('Two.');
    await tts.start('Three.');

    final started = await states.waitFor(TtsState.start);
    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
    await states.eventsDuring(const Duration(seconds: 2));

    expect(states.events.where((s) => s == TtsState.stop), hasLength(1));
    expect(states.events.last, TtsState.stop);
  });

  testWidgets('add mode: honors pre and post silences', (_) async {
    if (!await ttsReady()) return;

    await tts.start(
      _shortText,
      options: const TtsOptions(
        preSilence: Duration(milliseconds: 300),
        postSilence: Duration(milliseconds: 300),
      ),
    );

    final started = await states.waitFor(TtsState.start);
    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
  });

  testWidgets('flush mode replaces current speech', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_longText);
    final started = await states.waitFor(TtsState.start);

    await tts.start(
      _shortText,
      options: const TtsOptions(mode: TtsQueueMode.flush),
    );

    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
    final after = await states.eventsDuring(const Duration(seconds: 2));

    // Flushed speech doesn't end the session on its own.
    expect(states.events.where((s) => s == TtsState.stop), hasLength(1));
    expect(after, isNot(contains(TtsState.start)));
  });

  testWidgets('stop while speaking', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_longText);
    await tts.start(_longText);
    final started = await states.waitFor(TtsState.start);

    await tts.stop();
    await states.waitFor(
      TtsState.stop,
      from: started,
      timeout: const Duration(seconds: 3),
    );

    // Nothing is left to speak.
    final after = await states.eventsDuring(const Duration(seconds: 3));
    expect(after, isNot(contains(TtsState.start)));
  });

  testWidgets('speaks again right after stop', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_longText);
    await states.waitFor(TtsState.start);

    await tts.stop();
    await tts.start(_longText);
    await Future<void>.delayed(const Duration(seconds: 2));

    // The stopped speech doesn't end the new one.
    expect(states.events.last, TtsState.start, reason: '${states.events}');

    final restarted = states.events.length - 1;
    await tts.stop();
    await states.waitFor(
      TtsState.stop,
      from: restarted,
      timeout: const Duration(seconds: 3),
    );
  });

  testWidgets('pause and resume', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_longText);
    final started = await states.waitFor(TtsState.start);
    await Future<void>.delayed(const Duration(seconds: 1));

    await tts.pause();
    final paused = await states.waitFor(TtsState.pause, from: started);

    // Paused speech doesn't end by itself.
    final whilePaused = await states.eventsDuring(const Duration(seconds: 1));
    expect(whilePaused, isNot(contains(TtsState.stop)));

    await tts.resume();
    final resumed = await states.waitFor(TtsState.start, from: paused);
    await states.waitFor(TtsState.stop, from: resumed, timeout: _speakTimeout);
  });

  testWidgets('resume without pause does not replay', (_) async {
    if (!await ttsReady()) return;

    await tts.start(_shortText);
    final started = await states.waitFor(TtsState.start);

    await tts.resume();

    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
    // A replay would still be playing right after Stop.
    await expectNoAudio();

    final after = await states.eventsDuring(const Duration(seconds: 2));
    expect(after, isNot(contains(TtsState.start)));
  });

  testWidgets('speaks again after dispose', (_) async {
    if (!await ttsReady()) return;

    await tts.dispose();
    await tts.start(_shortText);

    final started = await states.waitFor(TtsState.start);
    await states.waitFor(TtsState.stop, from: started, timeout: _speakTimeout);
  });

  testWidgets('first call after dispose waits for the new engine', (_) async {
    if (!await ttsReady()) return;

    // Back to an uninitialized engine.
    await tts.dispose();

    final languages = tts.getLanguages();
    expect(await languages.timeout(const Duration(seconds: 10)), isNotEmpty);
  });
}
