require "test_helper"

module QuestionEnhancement
  class ResultTest < ActiveSupport::TestCase
    test "suggestions defaults to an empty array when not given" do
      result = Result.new(provider_model: "test", enhanced_prompt: "Ok?")

      assert_equal [], result.suggestions
    end

    test "suggestions returns the given array" do
      result = Result.new(provider_model: "test", enhanced_prompt: "Ok?", suggestions: [ "Try multiple choice." ])

      assert_equal [ "Try multiple choice." ], result.suggestions
    end
  end
end
