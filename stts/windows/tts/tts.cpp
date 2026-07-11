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
        while (event.GetFrom(pThis->m_pVoice) == S_OK)
        {
            if (SPEI_END_INPUT_STREAM == event.eEventId)
            {
                pThis->m_utteranceQueued = max(0, pThis->m_utteranceQueued - 1);
                if (pThis->m_utteranceQueued == 0)
                {
                    pThis->m_stateEventHandler->Success(flutter::EncodableValue(0));
                }
            }

            event.Clear();
        }
    }

    inline std::string GetPitchTag(int pitch) {
        return "<pitch absmiddle=\"" + std::to_string(pitch) + "\"/>";
    }

    // We speak with SPF_IS_XML. Escape the text so SAPI says it as-is.
    inline std::string EscapeXml(const std::string& text) {
        std::string escaped;
        escaped.reserve(text.size());

        for (char c : text)
        {
            switch (c)
            {
            case '&': escaped += "&amp;"; break;
            case '<': escaped += "&lt;"; break;
            case '>': escaped += "&gt;"; break;
            default: escaped += c; break;
            }
        }

        return escaped;
    }

    // Attributes hold the locale identifier (e.g. 0x40C as String...). Convert it to ISO code.
    inline std::string LocaleFromLcid(LPCWSTR wValue) {
        wchar_t locale[LOCALE_NAME_MAX_LENGTH] = {};
        LCIDToLocaleName((LCID)std::strtol(CW2A(wValue), NULL, 16), locale, LOCALE_NAME_MAX_LENGTH, 0);

        return (std::string)CW2A(locale);
    }

    inline std::string GetSilenceTag(int silenceMs) {
        if (silenceMs > 0)
        {
            return "<silence msec=\"" + std::to_string(silenceMs) + "\"/>";
        }

        return "";
    }

    void Tts::Start(std::string text, std::unique_ptr<TtsOptions> options)
    {
        ThrowIfFailed(CreateVoice());

        DWORD flags = SPDF_PRONUNCIATION | SPF_ASYNC | SPF_IS_XML;
        if (options->mode.compare("flush") == 0)
        {
            flags |= SPF_PURGEBEFORESPEAK;
        }

        text = 
            GetPitchTag(m_pitch)
            +
            GetSilenceTag(options->preSilenceMs)
            +
            EscapeXml(text)
            +
            GetSilenceTag(options->postSilenceMs);

        ThrowIfFailed(m_pVoice->Speak(Utf16FromUtf8(text).c_str(), flags, NULL));

        m_utteranceQueued++;

        if (m_utteranceQueued == 1)
        {
            m_stateEventHandler->Success(flutter::EncodableValue(1));
        }
    }

    void Tts::Stop()
    {
        m_utteranceQueued = 0;

        if (m_pVoice)
        {
            m_pVoice->Speak(L"", SPF_PURGEBEFORESPEAK, NULL);
            if (m_isPaused)
            {
                m_pVoice->Resume();
                m_isPaused = false;
            }
        }
    }

    void Tts::Pause()
    {
        if (m_pVoice && !m_isPaused)
        {
            ThrowIfFailed(m_pVoice->Pause());
            m_isPaused = true;

            m_stateEventHandler->Success(flutter::EncodableValue(2));
        }
    }
    
    void Tts::Resume()
    {
        if (m_pVoice && m_isPaused)
        {
            ThrowIfFailed(m_pVoice->Resume());
            m_isPaused = false;

            m_stateEventHandler->Success(flutter::EncodableValue(1));
        }
    }

    std::string Tts::GetLanguage()
    {
        std::string language = "";

        ThrowIfFailed(CreateVoice());

        ISpObjectToken* pToken = NULL;
        ThrowIfFailed(m_pVoice->GetVoice(&pToken));
        
        ISpDataKey* cpAttribKey;
        ThrowIfFailed(pToken->OpenKey(L"Attributes", &cpAttribKey));

        LPWSTR wValue;
        ThrowIfFailed(cpAttribKey->GetStringValue(L"Language", &wValue));

        // We get value as locale identifier (e.g. 0x40C as String...). We need to convert it to ISO code.
        wchar_t locale[LOCALE_NAME_MAX_LENGTH];
        LCIDToLocaleName((LCID)std::strtol(CW2A(wValue), NULL, 16), locale, LOCALE_NAME_MAX_LENGTH, 0);
        CoTaskMemFree(wValue);

        language = (std::string)CW2A(locale);

        cpAttribKey->Release();
        pToken->Release();

        return language;
    }

    void Tts::SetLanguage(std::string language)
    {
        if (GetLanguage() == language) { return; }

        auto voices = GetVoicesByLanguage(language);

        // Set first matching voice
        if (!voices.empty())
        {
            SetVoice(voices[0].id);
        }
    }

    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee431801(v=vs.85)#62-category-recognizers
    std::vector<std::string> Tts::GetLanguages()
    {
        std::vector<std::string> languages;

        for (const TtsVoice& voice : GetVoices())
        {
            // Don't duplicate results
            if (std::find(languages.begin(), languages.end(), voice.language) == languages.end()) {
                languages.push_back(voice.language);
            }
        }

        return languages;
    }

    void Tts::SetVoice(std::string voiceId)
    {
        ThrowIfFailed(CreateVoice());

        IEnumSpObjectTokens* cpEnum = NULL;
        ThrowIfFailed(SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum));

        ISpObjectToken* pToken = NULL;
        while (cpEnum->Next(1, &pToken, NULL) == S_OK)
        {
            LPWSTR wValue;
            ThrowIfFailed(pToken->GetStringValue(L"CLSID", &wValue));

            if (voiceId == (std::string)CW2A(wValue))
            {
                m_pVoice->SetVoice(pToken);

                CoTaskMemFree(wValue);
                pToken->Release();
                cpEnum->Release();
                return;
            }

            CoTaskMemFree(wValue);
            pToken->Release();
        }

        cpEnum->Release();
    }

    std::vector<TtsVoice> Tts::GetVoices()
    {
        std::vector<TtsVoice> voices;

        IEnumSpObjectTokens* cpEnum = NULL;
        // Report no voice when the platform has none to enumerate.
        if (FAILED(SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum))) return voices;

        ISpObjectToken* pToken = NULL;

        while (cpEnum->Next(1, &pToken, NULL) == S_OK)
        {
            TtsVoice voice;

            if (GetVoiceFromToken(pToken, voice))
            {
                voices.push_back(voice);
            }

            pToken->Release();
        }

        cpEnum->Release();

        return voices;
    }

    // Reads a voice token. Rejects it when its registration is incomplete.
    bool Tts::GetVoiceFromToken(ISpObjectToken* pToken, TtsVoice& voice)
    {
        LPWSTR wValue;

        if (FAILED(pToken->GetStringValue(L"CLSID", &wValue))) return false;
        voice.id = (std::string)CW2A(wValue);
        CoTaskMemFree(wValue);

        ISpDataKey* cpAttribKey;
        if (FAILED(pToken->OpenKey(L"Attributes", &cpAttribKey))) return false;

        auto hrLanguage = cpAttribKey->GetStringValue(L"Language", &wValue);
        if (SUCCEEDED(hrLanguage))
        {
            voice.language = LocaleFromLcid(wValue);
            CoTaskMemFree(wValue);
        }

        auto hrName = cpAttribKey->GetStringValue(L"Name", &wValue);
        if (SUCCEEDED(hrName))
        {
            voice.name = (std::string)CW2A(wValue);
            CoTaskMemFree(wValue);
        }

        // Gender is optional. Keep the default when the voice omits it.
        if (SUCCEEDED(cpAttribKey->GetStringValue(L"Gender", &wValue)))
        {
            std::string gender((std::string)CW2A(wValue));
            voice.gender = (gender == "Male") ? TtsVoiceGender::male : TtsVoiceGender::female;
            CoTaskMemFree(wValue);
        }

        cpAttribKey->Release();

        return SUCCEEDED(hrLanguage) && SUCCEEDED(hrName);
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
        ThrowIfFailed(CreateVoice());

        // Supported values range from -10 to 10. Incoming values are 0.1 - 10.
        auto fixedRate = min(max(rate, 0.1), 10);
        long adjustedRate = (fixedRate < 1) ? static_cast<long>(-1 / fixedRate) : static_cast<long>(fixedRate);

        ThrowIfFailed(m_pVoice->SetRate(adjustedRate));
    }
    void Tts::SetVolume(double volume)
    {
        ThrowIfFailed(CreateVoice());

        // The default base volume for all voices is 100 (full volume).
        auto adjustedVolume = static_cast<USHORT>(min(max(volume * 100, 0), 100));
        ThrowIfFailed(m_pVoice->SetVolume(adjustedVolume));
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

            // Set the notification type to receive end of speech notifications
            hr = m_pVoice->SetInterest(SPFEI(SPEI_END_INPUT_STREAM), SPFEI(SPEI_END_INPUT_STREAM));
            if (FAILED(hr)) return hr;

            hr = m_pVoice->SetNotifyCallbackFunction((SPNOTIFYCALLBACK*)Tts::SpeakEndNotifyCallback, (WPARAM)this, 0);
            if (FAILED(hr)) return hr;
        }

        return S_OK;
    }

    void Tts::ThrowIfFailed(HRESULT code)
    {
        if (FAILED(code))
        {
            throw code;
        }
    }

}
