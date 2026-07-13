module AiSummary
  # Deterministic, offline fallback summarizer. Used whenever no LLM provider
  # is configured, or when an LLM call fails, so report generation never breaks.
  class HeuristicProvider
    PROVIDER_MODEL = "local-heuristic".freeze

    def available?
      true
    end

    def call(open_text_answers:, survey:)
      @open_text_answers = open_text_answers

      AiSummary::Result.new(
        provider_model: PROVIDER_MODEL,
        summary_markdown: summary_markdown,
        raw_output: raw_output
      )
    end

    private
      attr_reader :open_text_answers

      def summary_markdown
        <<~MD.strip
          ## Executive summary
          #{executive_summary}

          ## Key themes
          #{themes.map { |theme| "- #{theme}" }.join("\n")}

          ## Sentiment
          #{sentiment_line}
        MD
      end

      def raw_output
        {
          themes: themes,
          sentiment: sentiment_label,
          positive_count: positive_count,
          neutral_count: neutral_count,
          negative_count: negative_count,
          total_open_text_answers: open_text_answers.count
        }
      end

      def themes
        base = []
        base << "Most feedback points to the need for clearer workflows" if open_text_answers.any? { |answer| answer.match?(/clear|workflow|process/i) }
        base << "Automation and AI support are recurring interests" if open_text_answers.any? { |answer| answer.match?(/ai|automation|assistant|tool/i) }
        base << "Communication and visibility are important" if open_text_answers.any? { |answer| answer.match?(/communicat|visible|transparent|update/i) }
        base << "The team wants fewer blockers and a smoother day-to-day flow" if open_text_answers.any? { |answer| answer.match?(/blocker|slow|friction|manual|time/i) }
        base.presence || [ "Feedback is limited so far, but the survey is ready for deeper analysis." ]
      end

      def positive_count
        open_text_answers.count { |answer| answer.match?(/good|great|helpful|clear|easy|love/i) }
      end

      def neutral_count
        open_text_answers.count { |answer| answer.match?(/ok|fine|maybe|suggest|consider/i) }
      end

      def negative_count
        open_text_answers.count { |answer| answer.match?(/slow|hard|confusing|difficult|bad|block/i) }
      end

      def sentiment_label
        return "positive" if positive_count > negative_count && positive_count > neutral_count
        return "negative" if negative_count > positive_count && negative_count > neutral_count

        "mixed"
      end

      def executive_summary
        if open_text_answers.empty?
          "There are no open-ended answers yet, so this report is waiting for more qualitative feedback."
        else
          "Based on #{open_text_answers.count} open-ended answer(s), the strongest signals are #{themes.first.downcase}."
        end
      end

      def sentiment_line
        case sentiment_label
        when "positive"
          "Overall tone looks positive."
        when "negative"
          "Overall tone looks negative and may need attention."
        else
          "Overall tone looks mixed, with both opportunities and concerns."
        end
      end
  end
end
