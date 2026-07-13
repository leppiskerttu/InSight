module QuestionEnhancement
  Result = Struct.new(:provider_model, :enhanced_prompt, :suggestions, keyword_init: true) do
    def suggestions
      self[:suggestions] || []
    end
  end
end
