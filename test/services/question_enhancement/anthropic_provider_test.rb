require "test_helper"

module QuestionEnhancement
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

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) do
        {
          content: [
            {
              type: "text",
              text: {
                enhanced_prompt: "What is your favorite coding language?",
                suggestions: [ "Consider multiple choice with common languages as options." ]
              }.to_json
            }
          ]
        }.to_json
      end

      result = provider.stub(:http_post, fake_response) do
        provider.call(prompt: "favorite coding language", question_type: "text")
      end

      assert_equal "claude-test", result.provider_model
      assert_equal "What is your favorite coding language?", result.enhanced_prompt
      assert_equal [ "Consider multiple choice with common languages as options." ], result.suggestions
    end

    test "defaults suggestions to an empty array when the response omits them" do
      provider = AnthropicProvider.new(api_key: "sk-test", model: "claude-test")

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) do
        { content: [ { type: "text", text: { enhanced_prompt: "Ok?" }.to_json } ] }.to_json
      end

      result = provider.stub(:http_post, fake_response) do
        provider.call(prompt: "test", question_type: "text")
      end

      assert_equal [], result.suggestions
    end

    test "raises ApiError when the API responds with a failure status" do
      provider = AnthropicProvider.new(api_key: "sk-test")

      fake_response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
      fake_response.define_singleton_method(:body) { "invalid api key" }

      assert_raises(AnthropicProvider::ApiError) do
        provider.stub(:http_post, fake_response) do
          provider.call(prompt: "test", question_type: "text")
        end
      end
    end

    test "raises ApiError when the response body is not valid JSON" do
      provider = AnthropicProvider.new(api_key: "sk-test")

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) { "not json" }

      assert_raises(AnthropicProvider::ApiError) do
        provider.stub(:http_post, fake_response) do
          provider.call(prompt: "test", question_type: "text")
        end
      end
    end

    test "raises ApiError when the response has no enhanced_prompt" do
      provider = AnthropicProvider.new(api_key: "sk-test")

      fake_response = Net::HTTPSuccess.new("1.1", "200", "OK")
      fake_response.define_singleton_method(:body) do
        { content: [ { type: "text", text: {}.to_json } ] }.to_json
      end

      assert_raises(AnthropicProvider::ApiError) do
        provider.stub(:http_post, fake_response) do
          provider.call(prompt: "test", question_type: "text")
        end
      end
    end
  end
end
