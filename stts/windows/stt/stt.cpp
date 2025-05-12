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

        CSpEvent event;
        while (event.GetFrom(pThis->m_pRecoContext) == S_OK) {
            if (SPEI_HYPOTHESIS == event.eEventId || SPEI_RECOGNITION == event.eEventId)
            {
                LPWSTR dstrText;
                event.RecoResult()->GetText((ULONG)SP_GETWHOLEPHRASE, (ULONG)SP_GETWHOLEPHRASE, TRUE, &dstrText, NULL);

                auto text = Utf8FromUtf16(dstrText);
                pThis->m_resultEventHandler->Success(flutter::EncodableValue(text));

                CoTaskMemFree(dstrText);
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
        std::string language = "";

        CreateRecognizer();

        if (m_pRecognizer)
        {
            ISpObjectToken* pToken = NULL;
            if (SUCCEEDED(m_pRecognizer->GetRecognizer(&pToken)))
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

    void Stt::SetLanguage(std::string language)
    {
        CreateRecognizer();

        if (m_pRecognizer)
        {
            IEnumSpObjectTokens* cpEnum = NULL;

            if (SUCCEEDED(SpEnumTokens(SPCAT_RECOGNIZERS, NULL, NULL, &cpEnum))) {
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

                            if ((std::string)CW2A(locale) == language)
                            {
                                m_pRecognizer->SetRecognizer(pToken);
                                cpAttribKey->Release();
                                cpEnum->Release();
                                return;
                            }
                        }

                        cpAttribKey->Release();
                    }

                    pToken->Release();
                }

                cpEnum->Release();
            }
        }
    }

    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ee431801(v=vs.85)#62-category-recognizers
    std::vector<std::string> Stt::GetLanguages()
    {
        std::vector<std::string> languages;

        IEnumSpObjectTokens* cpEnum = NULL;

        if (SUCCEEDED(SpEnumTokens(SPCAT_RECOGNIZERS, NULL, NULL, &cpEnum))) {
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

                        languages.push_back((std::string)CW2A(locale));
                    }

                    cpAttribKey->Release();
                }

                pToken->Release();
            }

            cpEnum->Release();
        }

        return languages;
    }

    void Stt::Start() {
        HRESULT hr = CreateRecognizer();
        if (FAILED(hr)) return;

        hr = m_pRecoContext->SetNotifyCallbackFunction((SPNOTIFYCALLBACK*)Stt::RecoEventCallback, (WPARAM)this, 0);
        auto interests = SPFEI(SPEI_RECOGNITION) | SPFEI(SPEI_HYPOTHESIS);
        hr = m_pRecoContext->SetInterest(interests, interests);

        ISpObjectToken* token;
        hr = SpGetDefaultTokenFromCategoryId(SPCAT_AUDIOIN, &token);
        hr = m_pRecognizer->SetInput(token, TRUE);

        hr = m_pRecoGrammar->LoadDictation(NULL, SPLO_STATIC);
        hr = m_pRecoGrammar->SetDictationState(SPRS_ACTIVE);

        m_stateEventHandler->Success(flutter::EncodableValue(1));
    }

    void Stt::Stop()
    {
        if (m_pRecoGrammar)
        {
            m_pRecoGrammar->SetDictationState(SPRS_INACTIVE);
            m_stateEventHandler->Success(flutter::EncodableValue(0));
        }
    }

    void Stt::Dispose()
    {
        Stop();

        if (m_pRecognizer)
        {
            m_pRecognizer->Release();
            m_pRecognizer = NULL;
        }

        if (m_pRecoContext)
        {
            m_pRecoContext->Release();
            m_pRecoContext = NULL;
        }

        if (m_pRecoGrammar)
        {
            m_pRecoGrammar->UnloadDictation();
            m_pRecoGrammar->Release();
            m_pRecoGrammar = NULL;
        }
    }

    HRESULT Stt::CreateRecognizer()
    {
        if (m_pRecognizer == NULL)
        {
            HRESULT hr = CoCreateInstance(CLSID_SpInprocRecognizer, NULL, CLSCTX_ALL, IID_ISpRecognizer, (void**)&m_pRecognizer);
            if (FAILED(hr)) return hr;
        }
        if (m_pRecoContext == NULL)
        {
            HRESULT hr = m_pRecognizer->CreateRecoContext(&m_pRecoContext);
            if (FAILED(hr)) return hr;
        }
        if (m_pRecoGrammar == NULL)
        {
            HRESULT hr = m_pRecoContext->CreateGrammar(0, &m_pRecoGrammar); // ID = 0
            if (FAILED(hr)) return hr;
        }

        return S_OK;
    }

    // Display the engine's training window
    void Stt::ShowTrainingUI(std::vector<std::wstring>& trainingTexts)
    {
        HRESULT hr = CreateRecognizer();
        if (FAILED(hr)) return;

        BOOL bSupported = false;

        hr = m_pRecognizer->IsUISupported(SPDUI_UserTraining, NULL, NULL, &bSupported);
        if (SUCCEEDED(hr) && bSupported)
        {
            std::wstring texts = L"";

            if (trainingTexts.size() != 0) {
                texts = trainingTexts[0];
                for (unsigned int i = 1; i < trainingTexts.size(); i++) {
                    texts += L"\n" + trainingTexts[i];
                }
            }

            auto wcTexts = texts.c_str();
            auto wcTextsLen = (ULONG)wcslen(wcTexts);

            m_pRecognizer->DisplayUI(
                NULL,
                NULL,
                SPDUI_UserTraining,
                wcTextsLen != 0 ? (void*)wcTexts : NULL,
                wcTextsLen != 0 ? wcTextsLen * sizeof(wchar_t) : NULL
            );
        }
    }

}