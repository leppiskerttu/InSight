module AiSummary
  Result = Struct.new(:provider_model, :summary_markdown, :raw_output, keyword_init: true)
end
