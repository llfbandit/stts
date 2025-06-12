#include "stts_plugin.h"
#include "utils.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "event_stream_handler.h"

#include <memory>
#include <sstream>

namespace stts {

	// static
	void SttsPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
		auto plugin = std::make_unique<SttsPlugin>(registrar);

		// STT
		auto sttMethodChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
			registrar->messenger(), "com.llfbandit.stt/methods",
			&flutter::StandardMethodCodec::GetInstance());		

		sttMethodChannel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->SttHandleMethodCall(call, std::move(result));
			});

		// TTS
		auto ttsMethodChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
			registrar->messenger(), "com.llfbandit.tts/methods",
			&flutter::StandardMethodCodec::GetInstance());

		ttsMethodChannel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->TtsHandleMethodCall(call, std::move(result));
			});

		registrar->AddPlugin(std::move(plugin));
	}

	SttsPlugin::SttsPlugin(flutter::PluginRegistrarWindows* registrar) {
		// STT
		auto sttStateEventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
			registrar->messenger(), "com.llfbandit.stt/states",
			&StandardMethodCodec::GetInstance());

		auto sttStateEventHandler = new EventStreamHandler();
		std::unique_ptr<StreamHandler<EncodableValue>> pSttStateEventHandler{ static_cast<StreamHandler<EncodableValue>*>(sttStateEventHandler) };
		sttStateEventChannel->SetStreamHandler(std::move(pSttStateEventHandler));

		auto sttResultEventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
			registrar->messenger(), "com.llfbandit.stt/results",
			&StandardMethodCodec::GetInstance());

		auto sttResultEventHandler = new EventStreamHandler();
		std::unique_ptr<StreamHandler<EncodableValue>> pSttResultEventHandler{ static_cast<StreamHandler<EncodableValue>*>(sttResultEventHandler) };
		sttResultEventChannel->SetStreamHandler(std::move(pSttResultEventHandler));

		mStt = std::make_unique<Stt>(sttStateEventHandler, sttResultEventHandler);

		// TTS
		auto ttsStateEventChannel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
			registrar->messenger(), "com.llfbandit.tts/states",
			&StandardMethodCodec::GetInstance());

		auto ttsStateEventHandler = new EventStreamHandler();
		std::unique_ptr<StreamHandler<EncodableValue>> pTtsStateEventHandler{ static_cast<StreamHandler<EncodableValue>*>(ttsStateEventHandler) };
		ttsStateEventChannel->SetStreamHandler(std::move(pTtsStateEventHandler));

		mTts = std::make_unique<Tts>(ttsStateEventHandler);
	}

	SttsPlugin::~SttsPlugin() {
	}

	void SttsPlugin::SttHandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

		auto method = method_call.method_name();

		if (method.compare("isSupported") == 0) {
			result->Success(flutter::EncodableValue(mStt->IsSupported()));
		}
		else if (method.compare("hasPermission") == 0) {
			result->Success(flutter::EncodableValue(true));
		}
		else if (method.compare("getLanguage") == 0) {
			try
			{
				result->Success(flutter::EncodableValue(mStt->getLanguage()));
			} catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("setLanguage") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			std::string language;
			GetValueFromEncodableMap(mapArgs, "language", language);

			try
			{
				mStt->SetLanguage(language);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("getLanguages") == 0) {
			try
			{
				auto languages = mStt->GetLanguages();

				flutter::EncodableList encodableLanguages;
				for (int i = 0; i < languages.size(); ++i)
				{
					encodableLanguages.push_back(EncodableValue(languages[i]));
				}

				result->Success(encodableLanguages);
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("start") == 0) {
			try
			{
				mStt->Start();
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("stop") == 0) {
			mStt->Stop();
			result->Success(flutter::EncodableValue(NULL));
		}
		else if (method.compare("windows.showTrainingUI") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);

			flutter::EncodableList trainingTexts;
			GetValueFromEncodableMap(mapArgs, "trainingTexts", trainingTexts);

			std::vector<std::wstring> texts;
			for (flutter::EncodableValue trainingText : trainingTexts) {
				texts.push_back(Utf16FromUtf8(std::get<std::string>(trainingText)));
			}

			try
			{
				mStt->ShowTrainingUI(texts);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("dispose") == 0) {
			mStt->Dispose();
			result->Success(flutter::EncodableValue(NULL));
		}
		else {
			result->NotImplemented();
		}
	}

	void SttsPlugin::TtsHandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

		auto method = method_call.method_name();

		if (method.compare("isSupported") == 0) {
			result->Success(flutter::EncodableValue(mTts->IsSupported()));
		}
		else if (method.compare("start") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			std::string text;
			GetValueFromEncodableMap(mapArgs, "text", text);
			std::string mode;
			GetValueFromEncodableMap(mapArgs, "mode", mode);

			try
			{
				mTts->Start(text, mode);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}			
		}
		else if (method.compare("stop") == 0) {
			mTts->Stop();
			result->Success(flutter::EncodableValue(NULL));
		}
		else if (method.compare("pause") == 0) {
			try
			{
				mTts->Pause();
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("resume") == 0) {
			try
			{
				mTts->Resume();
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("getLanguage") == 0) {
			try
			{
				result->Success(flutter::EncodableValue(mTts->GetLanguage()));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("setLanguage") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			std::string language;
			GetValueFromEncodableMap(mapArgs, "language", language);

			try
			{
				mTts->SetLanguage(language);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("getLanguages") == 0) {
			try
			{
				auto languages = mTts->GetLanguages();

				flutter::EncodableList encodableLanguages;
				for (int i = 0; i < languages.size(); ++i)
				{
					encodableLanguages.push_back(EncodableValue(languages[i]));
				}

				result->Success(encodableLanguages);
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("setVoice") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			std::string voiceId;
			GetValueFromEncodableMap(mapArgs, "voiceId", voiceId);

			try
			{
				mTts->SetVoice(voiceId);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("getVoices") == 0) {
			try
			{
				auto voices = mTts->GetVoices();

				flutter::EncodableList encodableVoices;
				for (TtsVoice voice : voices)
				{
					encodableVoices.push_back(EncodableMap({
						{EncodableValue("id"), EncodableValue(voice.id)},
						{EncodableValue("language"), EncodableValue(voice.language)},
						{EncodableValue("languageInstalled"), EncodableValue(voice.languageInstalled)},
						{EncodableValue("name"), EncodableValue(voice.name)},
						{EncodableValue("networkRequired"), EncodableValue(voice.networkRequired)},
						{EncodableValue("gender"), EncodableValue(ttsVoiceGenderToString(voice.gender))}
						}));
				}

				result->Success(encodableVoices);
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("getVoicesByLanguage") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			std::string language;
			GetValueFromEncodableMap(mapArgs, "language", language);

			try
			{
				auto voices = mTts->GetVoicesByLanguage(language);

				flutter::EncodableList encodableVoices;
				for (TtsVoice voice : voices)
				{
					encodableVoices.push_back(EncodableMap({
						{EncodableValue("id"), EncodableValue(voice.id)},
						{EncodableValue("language"), EncodableValue(voice.language)},
						{EncodableValue("languageInstalled"), EncodableValue(voice.languageInstalled)},
						{EncodableValue("name"), EncodableValue(voice.name)},
						{EncodableValue("networkRequired"), EncodableValue(voice.networkRequired)},
						{EncodableValue("gender"), EncodableValue(ttsVoiceGenderToString(voice.gender))}
						}));
				}

				result->Success(encodableVoices);
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("setPitch") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			double pitch;
			GetValueFromEncodableMap(mapArgs, "pitch", pitch);

			mTts->SetPitch(pitch);
			result->Success(flutter::EncodableValue(NULL));
		}
		else if (method.compare("setRate") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			double rate;
			GetValueFromEncodableMap(mapArgs, "rate", rate);

			try
			{
				mTts->SetRate(rate);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("setVolume") == 0) {
			const auto args = method_call.arguments();
			const auto* mapArgs = std::get_if<flutter::EncodableMap>(args);
			double volume;
			GetValueFromEncodableMap(mapArgs, "volume", volume);

			try
			{
				mTts->SetVolume(volume);
				result->Success(flutter::EncodableValue(NULL));
			}
			catch (HRESULT hr) {
				result->Error(std::to_string(hr), GetErrorMessage(hr));
			}
		}
		else if (method.compare("dispose") == 0) {
			mTts->Dispose();
			result->Success(flutter::EncodableValue(NULL));
		}
		else {
			result->NotImplemented();
		}
	}

	std::string SttsPlugin::ttsVoiceGenderToString(TtsVoiceGender gender) {
		switch (gender) {
		case male:		return "male";
		case female:	return "female";
		default:		return "unspecified";
		}
	}

	std::string SttsPlugin::GetErrorMessage(HRESULT hr)
	{
		_com_error err(hr);
		return Utf8FromUtf16(err.ErrorMessage());
	}

}  // namespace stts
