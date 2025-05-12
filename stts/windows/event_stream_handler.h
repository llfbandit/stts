#ifndef EVENT_STREAM_HANDLER_HEADER
#define EVENT_STREAM_HANDLER_HEADER

#include <flutter/event_channel.h>

namespace stts {

    using namespace flutter;

    class EventStreamHandler : public StreamHandler<EncodableValue> {
    public:
        EventStreamHandler() = default;

        virtual ~EventStreamHandler() = default;

        void Success(const EncodableValue& data) {
            if (m_sink.get()) m_sink.get()->Success(data);
        }

        void Error(const std::string& error_code, const std::string& error_message, const EncodableValue& error_details) {
            if (m_sink.get())
                m_sink.get()->Error(error_code, error_message, error_details);
        }

    protected:
        std::unique_ptr<StreamHandlerError<EncodableValue>> OnListenInternal(const EncodableValue* arguments, std::unique_ptr<EventSink<EncodableValue>>&& events) override {
            m_sink = std::move(events);
            return nullptr;
        }

        std::unique_ptr<StreamHandlerError<EncodableValue>> OnCancelInternal(const EncodableValue* arguments) override {
            m_sink.release();
            return nullptr;
        }

    private:
        std::unique_ptr<EventSink<EncodableValue>> m_sink;
    };

}

#endif