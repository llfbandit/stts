#include <iostream>
#include <string>
#include <vector>
#include "../event_stream_handler.h"

#include <sapi.h>
#pragma warning(disable:4996)
#include <sphelper.h>
#pragma warning(default: 4996)

namespace stts {

	class Stt
	{
	public:
		Stt(EventStreamHandler* stateEventHandler, EventStreamHandler* resultEventHandler);
		~Stt();

		bool IsSupported();
		std::string getLanguage();
		void SetLanguage(std::string language);
		std::vector<std::string> GetLanguages();
		void Start();
		void Stop();
		void ShowTrainingUI(std::vector<std::wstring>& trainingTexts);
		void Dispose();

		static void RecoEventCallback(WPARAM wParam, LPARAM lParam);

	private:
		ISpRecognizer* m_pRecognizer;
		ISpRecoContext* m_pRecoContext;
		ISpRecoGrammar* m_pRecoGrammar;

		EventStreamHandler* m_stateEventHandler;
		EventStreamHandler* m_resultEventHandler;

		HRESULT CreateRecognizer();
	};

}