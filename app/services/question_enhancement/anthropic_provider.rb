require "net/http"

module QuestionEnhancement
  # Calls Anthropic's Messages API to rephrase a draft survey question into a
  # clearer, complete question. Only used when ANTHROPIC_API_KEY is present;
  # QuestionEnhancer falls back to HeuristicProvider for any failure.
  class AnthropicProvider
    class ApiError < StandardError; end

    ENDPOINT = URI("https://api.anthropic.com/v1/messages").freeze
    DEFAULT_MODEL = "claude-3-5-haiku-latest".freeze
    ANTHROPIC_VERSION = "2023-06-01".freeze

    SYSTEM_PROMPT = <<~PROMPT.strip
      You are a survey design assistant. You are given a project manager's
      rough draft of a single survey question, plus its answer type. Rewrite
      it into a single clear, complete, well-phrased question in the same
      language as the draft. Keep it concise and neutral, do not change what
      it is asking about, and do not add extra questions.

      Also suggest 1-3 short, concrete ways the question could be made even
      better — for example a more useful answer type (e.g. multiple choice
      instead of free text, with example options), a more specific angle, or
      a natural follow-up question. Each suggestion must be one sentence.
      Skip a suggestion category if there is nothing meaningful to add.

      Respond with JSON only, matching this exact shape:
      {"enhanced_prompt": string, "suggestions": array of 1-3 short strings}
    PROMPT

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL))
      @api_key = api_key
      @model = model
    end

    attr_reader :model

    def available?
      @api_key.present?
    end

    def call(prompt:, question_type:)
      data = request_enhancement(prompt, question_type)
      build_result(data)
    end

    private
      def request_enhancement(prompt, question_type)
        response = http_post(request_body(prompt, question_type))

        unless response.is_a?(Net::HTTPSuccess)
          raise ApiError, "Anthropic API returned #{response.code}: #{response.body}"
        end

        text = JSON.parse(response.body).dig("content", 0, "text")
        raise ApiError, "Anthropic API response had no content" if text.blank?

        JSON.parse(text)
      rescue JSON::ParserError => e
        raise ApiError, "Could not parse Anthropic response: #{e.message}"
      end

      def request_body(prompt, question_type)
        {
          model: @model,
          max_tokens: 200,
          system: SYSTEM_PROMPT,
          messages: [ { role: "user", content: user_prompt(prompt, question_type) } ]
        }
      end

      def user_prompt(prompt, question_type)
        <<~PROMPT
          Answer type: #{question_type}
          Draft question: #{prompt}
        PROMPT
      end

      def http_post(body)
        request = Net::HTTP::Post.new(ENDPOINT)
        request["x-api-key"] = @api_key
        request["anthropic-version"] = ANTHROPIC_VERSION
        request["content-type"] = "application/json"
        request.body = body.to_json

        Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, read_timeout: 20) do |http|
          http.request(request)
        end
      end

      def build_result(data)
        enhanced_prompt = data["enhanced_prompt"].presence
        raise ApiError, "Anthropic API response had no enhanced_prompt" if enhanced_prompt.blank?

        QuestionEnhancement::Result.new(
          provider_model: @model,
          enhanced_prompt: enhanced_prompt,
          suggestions: Array(data["suggestions"]).map(&:to_s).reject(&:blank?)
        )
      end
  end
end
