class AiReportGenerator
  def self.call(survey)
    new(survey).call
  end

  def initialize(survey, provider: AiSummary::AnthropicProvider.new)
    @survey = survey
    @provider = provider
  end

  def call
    report = @survey.ai_reports.create!(
      status: :pending,
      provider_model: attempted_provider_model,
      generated_at: Time.current
    )

    result = generate_result

    report.update!(
      status: :completed,
      provider_model: result.provider_model,
      summary_markdown: result.summary_markdown,
      raw_output: result.raw_output,
      generated_at: Time.current
    )

    report
  rescue StandardError => e
    report&.update!(status: :failed, raw_output: { error: e.message }, generated_at: Time.current)
    raise
  end

  private
    def generate_result
      if @provider.available?
        begin
          return @provider.call(open_text_answers: open_text_answers, survey: @survey)
        rescue StandardError => e
          Rails.logger.warn("[AiReportGenerator] #{@provider.class} failed, falling back to heuristic: #{e.message}")
        end
      end

      heuristic_provider.call(open_text_answers: open_text_answers, survey: @survey)
    end

    def attempted_provider_model
      @provider.available? ? @provider.model : heuristic_provider.class::PROVIDER_MODEL
    end

    def heuristic_provider
      @heuristic_provider ||= AiSummary::HeuristicProvider.new
    end

    def open_text_answers
      @open_text_answers ||= @survey.questions.text.flat_map do |question|
        question.answers.where.not(value_text: [ nil, "" ]).pluck(:value_text)
      end
    end
end
