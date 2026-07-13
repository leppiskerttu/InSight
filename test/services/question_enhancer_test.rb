require "test_helper"

class QuestionEnhancerTest < ActiveSupport::TestCase
  test "falls back to the heuristic provider when no LLM provider is configured" do
    unavailable_provider = Class.new do
      def available?
        false
      end
    end.new

    result = QuestionEnhancer.call(prompt: "favorite coding language", question_type: "text", provider: unavailable_provider)

    assert_equal "local-heuristic", result.provider_model
    assert_equal "Favorite coding language?", result.enhanced_prompt
  end

  test "falls back to the heuristic provider when the configured LLM provider fails" do
    failing_provider = Class.new do
      def available?
        true
      end

      def call(**)
        raise "boom"
      end
    end.new

    result = QuestionEnhancer.call(prompt: "favorite coding language", question_type: "text", provider: failing_provider)

    assert_equal "local-heuristic", result.provider_model
    assert_equal "Favorite coding language?", result.enhanced_prompt
  end

  test "uses the LLM provider when it is available and succeeds" do
    fake_result = QuestionEnhancement::Result.new(
      provider_model: "claude-test",
      enhanced_prompt: "What is your favorite coding language?",
      suggestions: [ "Consider multiple choice with common languages as options." ]
    )

    succeeding_provider = Class.new do
      def available?
        true
      end

      def call(**)
        @result
      end

      def with_result(result)
        @result = result
        self
      end
    end.new.with_result(fake_result)

    result = QuestionEnhancer.call(prompt: "favorite coding language", question_type: "text", provider: succeeding_provider)

    assert_equal "claude-test", result.provider_model
    assert_equal "What is your favorite coding language?", result.enhanced_prompt
    assert_equal [ "Consider multiple choice with common languages as options." ], result.suggestions
  end
end
