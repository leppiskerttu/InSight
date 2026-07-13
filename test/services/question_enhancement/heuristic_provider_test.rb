require "test_helper"

module QuestionEnhancement
  class HeuristicProviderTest < ActiveSupport::TestCase
    test "available? is always true" do
      assert HeuristicProvider.new.available?
    end

    test "capitalizes and adds a trailing question mark" do
      result = HeuristicProvider.new.call(prompt: "favorite coding language", question_type: "text")

      assert_equal "local-heuristic", result.provider_model
      assert_equal "Favorite coding language?", result.enhanced_prompt
      assert_equal [], result.suggestions
    end

    test "does not duplicate a trailing question mark" do
      result = HeuristicProvider.new.call(prompt: "how satisfied are you?", question_type: "scale")

      assert_equal "How satisfied are you?", result.enhanced_prompt
    end

    test "replaces trailing period or exclamation mark with a question mark" do
      result = HeuristicProvider.new.call(prompt: "what tool helps most.", question_type: "text")

      assert_equal "What tool helps most?", result.enhanced_prompt
    end

    test "returns the blank prompt unchanged" do
      result = HeuristicProvider.new.call(prompt: "", question_type: "text")

      assert_equal "", result.enhanced_prompt
    end
  end
end
