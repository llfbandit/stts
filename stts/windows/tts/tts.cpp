#include "tts.h"
#include "../utils.h"

namespace stts {

    Tts::Tts(EventStreamHandler* stateEventHandler) :
        m_stateEventHandler(stateEventHandler),
        m_pVoice(NULL),
        m_pitch(0),
        m_isPaused(false),
        m_utteranceQueued(0)
    {
    }

    Tts::~Tts() {
        Dispose();
    }

    bool Tts::IsSupported()
    {
        return CreateVoice() == S_OK;
    }

    // static
    void __stdcall Tts::SpeakEndNotifyCallback(WPARAM wParam, LPARAM lParam) {
        auto pThis = (Tts*)wParam;

        CSpEvent event;
        while (event.GetFrom(pThis->m_pVoice) == S_OK) {
            if (SPEI_END_INPUT_STREAM == event.eEventId)
            {
                pThis->m_utteranceQueued--;

                if (pThis->m_utteranceQueued == 0)
                {
                    pThis->m_stateEventHandler->Success(flutter::EncodableValue(0));
                }
            }

            event.Clear();
        }
    }

    void Tts::Start(std::string text)
    {
        HRESULT hr = CreateVoice();
        if (FAILED(hr)) return;

        // Set the notification type to receive end of speech notifications
        m_pVoice->SetInterest(SPFEI(SPEI_END_INPUT_STREAM), SPFEI(SPEI_END_INPUT_STREAM));
        m_pVoice->SetNotifyCallbackFunction((SPNOTIFYCALLBACK*)Tts::SpeakEndNotifyCallback, (WPARAM)this, 0);

        const std::string pitchXml = "<pitch absmiddle=\"" + std::to_string(m_pitch) + "\"/>";

        hr = m_pVoice->Speak(Utf16FromUtf8(pitchXml + text).c_str(), SPDF_PRONUNCIATION | SPF_ASYNC | SPF_IS_XML, NULL);
        if (FAILED(hr)) return;

        m_utteranceQueued++;

        m_stateEventHandler->Success(flutter::EncodableValue(1));
    }

    void Tts::Stop()
    {
        if (m_pVoice)
        {
            m_pVoice->Speak(L"", SPF_PURGEBEFORESPEAK, NULL);
            if (m_isPaused)
            {
                m_pVoice->Resume();
                m_isPaused = false;
            }

            m_utteranceQueued = 0;

            m_stateEventHandler->Success(flutter::EncodableValue(0));
        }
    }

    void Tts::Pause()
    {
        if (m_pVoice && !m_isPaused)
        {
            m_pVoice->Pause();
            m_isPaused = true;

            m_stateEventHandler->Success(flutter::EncodableValue(2));
        }
    }
    
    void Tts::Resume()
    {
        if (m_pVoice && m_isPaused)
        {
            m_pVoice->Resume();
            m_isPaused = false;

            m_stateEventHandler->Success(flutter::EncodableValue(1));
        }
    }

    std::string Tts::GetLanguage()
    {
        std::string language = "";

        CreateVoice();

        if (m_pVoice)
        {
            ISpObjectToken* pToken = NULL;
            if (SUCCEEDED(m_pVoice->GetVoice(&pToken)))
            {
                ISpDataKey* cpAttribKey;

                if (SUCCEEDED(pToken->OpenKey(L"Attributes", &cpAttribKey))) {
                    LPWSTR wValue;

                    if (SUCCEEDED(cpAttribKey->GetStringValue(L"Language", &wValue))) {
                        // We get value as locale identifier (e.g. 0x40C as String...). We need to convert it to ISO code.
                        wchar_t locale[LOCALE_NAME_MAX_LENGTH];
                        LCIDToLocaleName((LCID)std::strtol(CW2A(wValue), NULL, 16), locale, LOCALE_NAME_MAX_LENGTH, 0);
                        CoTaskMemFree(wValue);

                        language = (std::string)CW2A(locale);                        
                    }

                    cpAttribKey->Release();
                }

            }
        }

        return language;
    }

    void Tts::SetLanguage(std::string language)
    {
        if (GetLanguage() == language) { return; }

        auto voices = GetVoicesByLanguage(language);

        // Set first matching voice
        for (TtsVoice voice : voices)
        {
            if (voice.language == language)
            {
                SetVoice(voice.id);
            }
        }
    }

    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee431801(v=vs.85)#62-category-recognizers
    std::vector<std::string> Tts::GetLanguages()
    {
        std::vector<std::string> languages;

        IEnumSpObjectTokens* cpEnum = NULL;

        if (SUCCEEDED(SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum))) {
            ISpObjectToken* pToken = NULL;

            while (cpEnum->Next(1, &pToken, NULL) == S_OK) {
                ISpDataKey* cpAttribKey;

                if (SUCCEEDED(pToken->OpenKey(L"Attributes", &cpAttribKey))) {
                    LPWSTR wValue;

                    if (SUCCEEDED(cpAttribKey->GetStringValue(L"Language", &wValue))) {
                        // We get value as locale identifier (e.g. 0x40C as String...). We need to convert it to ISO code.
                        wchar_t locale[LOCALE_NAME_MAX_LENGTH];
                        LCIDToLocaleName((LCID)std::strtol(CW2A(wValue), NULL, 16), locale, LOCALE_NAME_MAX_LENGTH, 0);
                        CoTaskMemFree(wValue);

                        std::string language((std::string)CW2A(locale));

                        // Don't duplicate results
                        if (std::find(languages.begin(), languages.end(), language) == languages.end()) {
                            languages.push_back(language);
                        }
                    }

                    cpAttribKey->Release();
                }

                pToken->Release();
            }

            cpEnum->Release();
        }

        return languages;
    }

    void Tts::SetVoice(std::string voiceId)
    {
        CreateVoice();

        if (m_pVoice)
        {
            IEnumSpObjectTokens* cpEnum = NULL;

            if (SUCCEEDED(SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum))) {
                ISpObjectToken* pToken = NULL;

                while (cpEnum->Next(1, &pToken, NULL) == S_OK) {                    
                    LPWSTR wValue;

                    if (SUCCEEDED(pToken->GetStringValue(L"CLSID", &wValue))) {
                        if (voiceId == (std::string)CW2A(wValue))
                        {
                            m_pVoice->SetVoice(pToken);

                            pToken->Release();
                            cpEnum->Release();
                            return;
                        }

                        CoTaskMemFree(wValue);
                    }

                    pToken->Release();
                }

                cpEnum->Release();
            }
        }
    }

    std::vector<TtsVoice> Tts::GetVoices()
    {
        std::vector<TtsVoice> voices;

        IEnumSpObjectTokens* cpEnum = NULL;

        if (SUCCEEDED(SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum))) {
            ISpObjectToken* pToken = NULL;

            while (cpEnum->Next(1, &pToken, NULL) == S_OK) {
                ISpDataKey* cpAttribKey;
                LPWSTR wValue;
                TtsVoice voice;

                if (SUCCEEDED(pToken->GetStringValue(L"CLSID", &wValue))) {
                    voice.id = (std::string)CW2A(wValue);

                    CoTaskMemFree(wValue);
                }

                if (SUCCEEDED(pToken->OpenKey(L"Attributes", &cpAttribKey))) {                   

                    if (SUCCEEDED(cpAttribKey->GetStringValue(L"Language", &wValue))) {
                        // We get value as locale identifier (e.g. 0x40C as String...). We need to convert it to ISO code.
                        wchar_t locale[LOCALE_NAME_MAX_LENGTH];
                        LCIDToLocaleName((LCID)std::strtol(CW2A(wValue), NULL, 16), locale, LOCALE_NAME_MAX_LENGTH, 0);
                        CoTaskMemFree(wValue);

                        voice.language = (std::string)CW2A(locale);                        
                    }

                    if (SUCCEEDED(cpAttribKey->GetStringValue(L"Name", &wValue))) {
                        voice.name = (std::string)CW2A(wValue);

                        CoTaskMemFree(wValue);
                    }

                    if (SUCCEEDED(cpAttribKey->GetStringValue(L"Gender", &wValue))) {
                        std::string gender((std::string)CW2A(wValue));
                        voice.gender = (gender == "Male") ? TtsVoiceGender::male : TtsVoiceGender::female;

                        CoTaskMemFree(wValue);
                    }

                    voices.push_back(voice);

                    cpAttribKey->Release();
                }

                pToken->Release();
            }

            cpEnum->Release();
        }

        return voices;
    }

    std::vector<TtsVoice> Tts::GetVoicesByLanguage(std::string language)
    {
        std::vector<TtsVoice> voices;
        auto allVoices = GetVoices();

        for (TtsVoice voice : allVoices)
        {
            if (voice.language == language)
            {
                voices.push_back(voice);
            }
        }

        return voices;
    }

    void Tts::SetPitch(double pitch)
    {
        // Supported values range from -10 to 10. Incoming values are 0 - 2.
        auto fixedPitch = min(max(pitch, 0.0), 2.0);
        auto adjustedPitch = ((fixedPitch - 1) * 20) / 2;

        m_pitch = static_cast<int>(round(adjustedPitch));
    }
    void Tts::SetRate(double rate)
    {
        CreateVoice();

        if (m_pVoice)
        {
            // Supported values range from -10 to 10. Incoming values are 0.1 - 10.
            auto fixedRate = min(max(rate, 0.1), 10);
            long adjustedRate = (fixedRate < 1) ? static_cast<long>(-1 / fixedRate) : static_cast<long>(fixedRate);

            m_pVoice->SetRate(adjustedRate);
        }
    }
    void Tts::SetVolume(double volume)
    {
        CreateVoice();

        if (m_pVoice)
        {   // The default base volume for all voices is 100 (full volume).
            auto adjustedVolume = static_cast<USHORT>(min(max(volume * 100, 0), 100));
            m_pVoice->SetVolume(adjustedVolume);
        }
    }

    void Tts::Dispose()
    {
        Stop();

        if (m_pVoice)
        {
            m_pVoice->Release();
            m_pVoice = NULL;
        }

        m_pitch = 0;
        m_isPaused = false;
        m_utteranceQueued = 0;
    }

    HRESULT Tts::CreateVoice()
    {
        if (m_pVoice == NULL)
        {
            HRESULT hr = CoCreateInstance(CLSID_SpVoice, NULL, CLSCTX_ALL, IID_ISpVoice, (void**)&m_pVoice);
            if (FAILED(hr)) return hr;
        }

        return S_OK;
    }

}
