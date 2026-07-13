module QuestionEnhancement
  # Deterministic, offline fallback for question wording cleanup. Used whenever
  # no LLM provider is configured, or when an LLM call fails, so the "enhance"
  # action never breaks the question form.
  class HeuristicProvider
    PROVIDER_MODEL = "local-heuristic".freeze

    def available?
      true
    end

    def call(prompt:, question_type:)
      QuestionEnhancement::Result.new(
        provider_model: PROVIDER_MODEL,
        enhanced_prompt: cleaned_up(prompt),
        suggestions: []
      )
    end

    private
      def cleaned_up(prompt)
        text = prompt.to_s.strip
        return prompt.to_s if text.blank?

        text = text[0].upcase + text[1..]
        text = text.sub(/[.!]+\z/, "")
        text = "#{text}?" unless text.end_with?("?")
        text
      end
  end
end
