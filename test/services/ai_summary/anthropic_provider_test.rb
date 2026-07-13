require "test_helper"

module AiSummary
  class AnthropicProviderTest < ActiveSupport::TestCase
    test "available? is false without an api key" do
      provider = AnthropicProvider.new(api_key: nil)

      assert_not provider.available?
    end

    test "available? is true with an api key" do
      provider = AnthropicProvider.new(api_key: "sk-test")

      assert provider.available?
    end

    test "parses a successful Anthropic response into a Result" do
      provider = AnthropicProvider.new(api_key: "sk-test", model: "claude-test")
      survey = User.first.surveys.create!(title: "LLM test survey", status: :published)

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) do
        {
          content: [
            {
              type: "text",
              text: {
                executive_summary: "The team wants clearer workflows.",
                themes: [ "Workflow clarity", "Automation interest" ],
                sentiment: "mixed",
                sentiment_note: "Overall tone looks mixed."
              }.to_json
            }
          ]
        }.to_json
      end

      result = provider.stub(:http_post, fake_response) do
        provider.call(open_text_answers: [ "Please improve the workflow" ], survey: survey)
      end

      assert_equal "claude-test", result.provider_model
      assert_match "clearer workflows", result.summary_markdown
      assert_match "Workflow clarity", result.summary_markdown
      assert_equal "mixed", result.raw_output["sentiment"]
    end

    test "raises ApiError when the API responds with a failure status" do
      provider = AnthropicProvider.new(api_key: "sk-test")
      survey = User.first.surveys.create!(title: "LLM failure survey", status: :published)

      fake_response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
      fake_response.define_singleton_method(:body) { "invalid api key" }

      assert_raises(AnthropicProvider::ApiError) do
        provider.stub(:http_post, fake_response) do
          provider.call(open_text_answers: [ "test" ], survey: survey)
        end
      end
    end

    test "raises ApiError when the response body is not valid JSON" do
      provider = AnthropicProvider.new(api_key: "sk-test")
      survey = User.first.surveys.create!(title: "LLM malformed survey", status: :published)

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) { "not json" }

      assert_raises(AnthropicProvider::ApiError) do
        provider.stub(:http_post, fake_response) do
          provider.call(open_text_answers: [ "test" ], survey: survey)
        end
      end
    end
  end
end
