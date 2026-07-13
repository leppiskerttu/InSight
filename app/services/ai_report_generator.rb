class AiReportGenerator
  # Fills in an already-created, pending AiReport. The pending record is
  # created synchronously (cheap, no external call) so the UI has something
  # to render immediately; this class does the slow part (the LLM call) and
  # is meant to be run from a background job.
  def self.call(report, provider: AiSummary::AnthropicProvider.new)
    new(report, provider: provider).call
  end

  def initialize(report, provider: AiSummary::AnthropicProvider.new)
    @report = report
    @survey = report.survey
    @provider = provider
  end

  def call
    result = generate_result

    @report.update!(
      status: :completed,
      provider_model: result.provider_model,
      summary_markdown: result.summary_markdown,
      raw_output: result.raw_output,
      generated_at: Time.current
    )

    @report
  rescue StandardError => e
    @report.update!(status: :failed, raw_output: { error: e.message }, generated_at: Time.current)
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

    def heuristic_provider
      @heuristic_provider ||= AiSummary::HeuristicProvider.new
    end

    def open_text_answers
      @open_text_answers ||= @survey.questions.text.flat_map do |question|
        question.answers.where.not(value_text: [ nil, "" ]).pluck(:value_text)
      end
    end
end
