class QuestionEnhancer
  def self.call(prompt:, question_type:, provider: QuestionEnhancement::OpenAiProvider.new)
    new(prompt: prompt, question_type: question_type, provider: provider).call
  end

  def initialize(prompt:, question_type:, provider:)
    @prompt = prompt
    @question_type = question_type
    @provider = provider
  end

  def call
    if @provider.available?
      begin
        return @provider.call(prompt: @prompt, question_type: @question_type)
      rescue StandardError => e
        Rails.logger.warn("[QuestionEnhancer] #{@provider.class} failed, falling back to heuristic: #{e.message}")
      end
    end

    heuristic_provider.call(prompt: @prompt, question_type: @question_type)
  end

  private
    def heuristic_provider
      @heuristic_provider ||= QuestionEnhancement::HeuristicProvider.new
    end
end
