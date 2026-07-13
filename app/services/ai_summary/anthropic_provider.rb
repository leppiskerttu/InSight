require "net/http"

module AiSummary
  # Calls Anthropic's Messages API to produce a structured summary of a
  # survey's open-ended answers. Only used when ANTHROPIC_API_KEY is present;
  # AiReportGenerator falls back to HeuristicProvider for any failure.
  class AnthropicProvider
    class ApiError < StandardError; end

    ENDPOINT = URI("https://api.anthropic.com/v1/messages").freeze
    DEFAULT_MODEL = "claude-3-5-haiku-latest".freeze
    ANTHROPIC_VERSION = "2023-06-01".freeze

    SYSTEM_PROMPT = <<~PROMPT.strip
      You are a research analyst summarizing open-ended survey responses for a
      project manager. Be concise and concrete, avoid generic filler, and base
      every claim strictly on the provided answers. Respond with JSON only,
      matching this exact shape:
      {"executive_summary": string, "themes": array of 2-4 short strings, "sentiment": "positive" | "negative" | "mixed", "sentiment_note": string}
    PROMPT

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL))
      @api_key = api_key
      @model = model
    end

    attr_reader :model

    def available?
      @api_key.present?
    end

    def call(open_text_answers:, survey:)
      data = request_summary(open_text_answers, survey)
      build_result(data)
    end

    private
      def request_summary(open_text_answers, survey)
        response = http_post(request_body(open_text_answers, survey))

        unless response.is_a?(Net::HTTPSuccess)
          raise ApiError, "Anthropic API returned #{response.code}: #{response.body}"
        end

        text = JSON.parse(response.body).dig("content", 0, "text")
        raise ApiError, "Anthropic API response had no content" if text.blank?

        JSON.parse(text)
      rescue JSON::ParserError => e
        raise ApiError, "Could not parse Anthropic response: #{e.message}"
      end

      def request_body(open_text_answers, survey)
        {
          model: @model,
          max_tokens: 700,
          system: SYSTEM_PROMPT,
          messages: [ { role: "user", content: user_prompt(open_text_answers, survey) } ]
        }
      end

      def user_prompt(open_text_answers, survey)
        <<~PROMPT
          Survey: #{survey.title}
          Open-ended answers (#{open_text_answers.size} total):
          #{open_text_answers.map { |answer| "- #{answer}" }.join("\n")}
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
        themes = Array(data["themes"]).presence || [ "No clear themes yet." ]

        markdown = <<~MD.strip
          ## Executive summary
          #{data["executive_summary"]}

          ## Key themes
          #{themes.map { |theme| "- #{theme}" }.join("\n")}

          ## Sentiment
          #{data["sentiment_note"].presence || data["sentiment"]}
        MD

        AiSummary::Result.new(
          provider_model: @model,
          summary_markdown: markdown,
          raw_output: data
        )
      end
  end
end
