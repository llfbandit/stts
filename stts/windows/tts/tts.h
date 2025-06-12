#include <iostream>
#include <string>
#include <vector>
#include "../event_stream_handler.h"

#include <sapi.h>
#pragma warning(disable:4996)
#include <sphelper.h>
#pragma warning(default: 4996)

namespace stts {

	enum TtsVoiceGender {
		unspecified,
		male,
		female
	};

	struct TtsVoice {
		std::string id;
		std::string language;
		bool languageInstalled = true;
		std::string name;
		bool networkRequired = false;
		TtsVoiceGender gender = unspecified;
	};

	class Tts
	{
	public:
		Tts(EventStreamHandler* stateEventHandler);
		~Tts();

		bool IsSupported();

		void Start(std::string text, std::string mode);
		void Stop();
		void Pause();
		void Resume();
		void Dispose();

		std::string GetLanguage();
		void SetLanguage(std::string language);
		std::vector<std::string> GetLanguages();

		void SetVoice(std::string voiceId);
		std::vector<TtsVoice> GetVoices();
		std::vector<TtsVoice> GetVoicesByLanguage(std::string language);

		void SetPitch(double pitch);
		void SetRate(double rate);
		void SetVolume(double volume);

		static void SpeakEndNotifyCallback(WPARAM wParam, LPARAM lParam);

	private:
		ISpVoice* m_pVoice;
		int m_pitch;
		bool m_isPaused;
		int m_utteranceQueued = 0;

		EventStreamHandler* m_stateEventHandler;

		HRESULT CreateVoice();
		void ThrowIfFailed(HRESULT code);		
	};

}
