# Uma linha JSON estruturada por requisição (latência, status, controller/action),
# correlacionada com o New Relic via trace.id/span.id e com o restante da cadeia
# (API Gateway -> Lambda -> Rails) via request_id (honra o header X-Request-Id de
# entrada — ver ActionDispatch::RequestId).
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:headers]&.[]("action_dispatch.request_id"),
      trace_id: ::NewRelic::Agent::Tracer.current_trace_id,
      span_id: ::NewRelic::Agent::Tracer.current_span_id
    }.compact
  end
end
