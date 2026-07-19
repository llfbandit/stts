#include "stt.h"
#include "../utils.h"

namespace stts {

    Stt::Stt(EventStreamHandler* stateEventHandler, EventStreamHandler* resultEventHandler) :
        m_stateEventHandler(stateEventHandler),
        m_resultEventHandler(resultEventHandler),
        m_pRecognizer(NULL),
        m_pRecoContext(NULL),
        m_pRecoGrammar(NULL)
    {
    }

    Stt::~Stt() {
        Dispose();
    }

    // static
    void __stdcall Stt::RecoEventCallback(WPARAM wParam, LPARAM lParam)
    {
        auto pThis = (Stt*)wParam;

        // A notification may still reach us after dispose.
        if (pThis->m_pRecoContext == NULL) return;

        CSpEvent event;
        if (event.GetFrom(pThis->m_pRecoContext) == S_OK)
        {
            if (SPEI_HYPOTHESIS == event.eEventId || SPEI_RECOGNITION == event.eEventId)
            {
                LPWSTR dstrText;
                HRESULT hr = event.RecoResult()->GetText((ULONG)SP_GETWHOLEPHRASE, (ULONG)SP_GETWHOLEPHRASE, TRUE, &dstrText, NULL);
                if (FAILED(hr))
                {
                    _com_error err(hr);
                    std::string msg = Utf8FromUtf16(err.ErrorMessage());
                    pThis->m_stateEventHandler->Error(std::to_string(hr), msg);
                }
                else
                {
                    auto text = Utf8FromUtf16(dstrText);
                    pThis->m_resultEventHandler->Success(flutter::EncodableMap({
                        {flutter::EncodableValue("text"), flutter::EncodableValue(text)},
                        {flutter::EncodableValue("isFinal"), flutter::EncodableValue(SPEI_RECOGNITION == event.eEventId)}
                    }));

                    CoTaskMemFree(dstrText);
                }
            }

            if (SPEI_RECOGNITION == event.eEventId) {
                pThis->Stop();
            }

            event.Clear();
        }
    }

    bool Stt::IsSupported()
    {
        return CreateRecognizer() == S_OK;
    }

    std::string Stt::getLanguage()
    {
        ThrowIfFailed(CreateRecognizer());

        CComPtr<ISpObjectToken> cpToken;
        ThrowIfFailed(m_pRecognizer->GetRecognizer(&cpToken));

        CComPtr<ISpDataKey> cpAttribKey;
        ThrowIfFailed(cpToken->OpenKey(L"Attributes", &cpAttribKey));

        LPWSTR wValue;
        ThrowIfFailed(cpAttribKey->GetStringValue(L"Language", &wValue));

        auto language = LocaleFromLcid(wValue);
        CoTaskMemFree(wValue);

        return language;
    }

    void Stt::SetLanguage(std::string language)
    {
        ThrowIfFailed(CreateRecognizer());

        CComPtr<IEnumSpObjectTokens> cpEnum;
        ThrowIfFailed(SpEnumTokens(SPCAT_RECOGNIZERS, NULL, NULL, &cpEnum));

        while (true)
        {
            CComPtr<ISpObjectToken> cpToken;
            if (cpEnum->Next(1, &cpToken, NULL) != S_OK) break;

            // Skip the recognizer when its registration is incomplete.
            CComPtr<ISpDataKey> cpAttribKey;
            if (FAILED(cpToken->OpenKey(L"Attributes", &cpAttribKey))) continue;

            LPWSTR wValue;
            if (FAILED(cpAttribKey->GetStringValue(L"Language", &wValue))) continue;

            auto tokenLanguage = LocaleFromLcid(wValue);
            CoTaskMemFree(wValue);

            if (tokenLanguage == language)
            {
                ThrowIfFailed(m_pRecognizer->SetRecognizer(cpToken));
                return;
            }
        }
    }

    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee431801(v=vs.85)#62-category-recognizers
    std::vector<std::string> Stt::GetLanguages()
    {
        std::vector<std::string> languages;

        CComPtr<IEnumSpObjectTokens> cpEnum;
        // Report no language when the platform has no recognizer to enumerate.
        if (FAILED(SpEnumTokens(SPCAT_RECOGNIZERS, NULL, NULL, &cpEnum))) return languages;

        while (true)
        {
            CComPtr<ISpObjectToken> cpToken;
            if (cpEnum->Next(1, &cpToken, NULL) != S_OK) break;

            // Skip the recognizer when its registration is incomplete.
            CComPtr<ISpDataKey> cpAttribKey;
            if (FAILED(cpToken->OpenKey(L"Attributes", &cpAttribKey))) continue;

            LPWSTR wValue;
            if (FAILED(cpAttribKey->GetStringValue(L"Language", &wValue))) continue;

            languages.push_back(LocaleFromLcid(wValue));
            CoTaskMemFree(wValue);
        }

        return languages;
    }

    void Stt::Start() {
        if (m_isListening) return;

        ThrowIfFailed(CreateRecognizer());

        ISpObjectToken* token = NULL;
        ThrowIfFailed(SpGetDefaultTokenFromCategoryId(SPCAT_AUDIOIN, &token));

        // SetInput keeps its own reference. Drop ours, even on failure.
        HRESULT hr = m_pRecognizer->SetInput(token, TRUE);
        token->Release();
        ThrowIfFailed(hr);

        ThrowIfFailed(m_pRecoGrammar->LoadDictation(NULL, SPLO_STATIC));
        ThrowIfFailed(m_pRecoGrammar->SetDictationState(SPRS_ACTIVE));
        ThrowIfFailed(m_pRecognizer->SetRecoState(SPRST_ACTIVE));

        m_isListening = true;
        m_stateEventHandler->Success(flutter::EncodableValue(1));
    }

    // Called from the recognition callback. Only stop dictation here,
    // releasing the context would tear down the notification source we run on.
    void Stt::Stop()
    {
        if (!m_isListening) return;

        m_isListening = false;

        if (m_pRecoGrammar)
        {
            m_pRecoGrammar->SetDictationState(SPRS_INACTIVE);
            m_pRecoGrammar->UnloadDictation();
        }

        // A running engine can't be reconfigured (SPERR_ENGINE_BUSY), e.g. input or language.
        if (m_pRecognizer)
        {
            m_pRecognizer->SetRecoState(SPRST_INACTIVE_WITH_PURGE);
        }

        m_stateEventHandler->Success(flutter::EncodableValue(0));
    }

    void Stt::Dispose()
    {
        Stop();

        // Release children before parents.
        if (m_pRecoGrammar)
        {
            m_pRecoGrammar->Release();
            m_pRecoGrammar = NULL;
        }

        if (m_pRecoContext)
        {
            m_pRecoContext->Release();
            m_pRecoContext = NULL;
        }

        if (m_pRecognizer)
        {
            m_pRecognizer->Release();
            m_pRecognizer = NULL;
        }
    }

    HRESULT Stt::CreateRecognizer()
    {
        HRESULT hr = S_OK;

        if (m_pRecognizer == NULL)
        {
            hr = CoCreateInstance(CLSID_SpInprocRecognizer, NULL, CLSCTX_ALL, IID_ISpRecognizer, (void**)&m_pRecognizer);
            if (FAILED(hr)) return hr;
        }
        if (m_pRecoContext == NULL)
        {
            hr = m_pRecognizer->CreateRecoContext(&m_pRecoContext);
            if (FAILED(hr)) return hr;

            // SAPI accepts one registration per context. Do it once, here.
            hr = m_pRecoContext->SetNotifyCallbackFunction((SPNOTIFYCALLBACK*)Stt::RecoEventCallback, (WPARAM)this, 0);

            auto interests = SPFEI(SPEI_RECOGNITION) | SPFEI(SPEI_HYPOTHESIS);
            if (SUCCEEDED(hr)) hr = m_pRecoContext->SetInterest(interests, interests);

            // Retry the registration on next call.
            if (FAILED(hr))
            {
                m_pRecoContext->Release();
                m_pRecoContext = NULL;
                return hr;
            }
        }
        if (m_pRecoGrammar == NULL)
        {
            hr = m_pRecoContext->CreateGrammar(0, &m_pRecoGrammar); // ID = 0
            if (FAILED(hr)) return hr;
        }

        return hr;
    }

    // Display the engine's training window
    void Stt::ShowTrainingUI(std::vector<std::wstring>& trainingTexts)
    {
        ThrowIfFailed(CreateRecognizer());

        BOOL bSupported = false;
        ThrowIfFailed(m_pRecognizer->IsUISupported(SPDUI_UserTraining, NULL, NULL, &bSupported));

        if (bSupported)
        {
            std::wstring texts = L"";

            if (trainingTexts.size() != 0) {
                texts = trainingTexts[0];
                for (unsigned int i = 1; i < trainingTexts.size(); i++)
                {
                    texts += L"\n" + trainingTexts[i];
                }
            }

            auto wcTexts = texts.c_str();
            auto wcTextsLen = (ULONG)wcslen(wcTexts);

            ThrowIfFailed(m_pRecognizer->DisplayUI(
                NULL,
                NULL,
                SPDUI_UserTraining,
                wcTextsLen != 0 ? (void*)wcTexts : NULL,
                wcTextsLen != 0 ? wcTextsLen * sizeof(wchar_t) : NULL
            ));
        }
    }

    void Stt::ThrowIfFailed(HRESULT code)
    {
        if (FAILED(code))
        {
            throw code;
        }
    }

}