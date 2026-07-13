require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "assigns a default position on create" do
    survey = surveys(:one)

    question = survey.questions.create!(
      prompt: "New question",
      question_type: "text"
    )

    assert_equal 2, question.position
  end

  test "renders options text from options" do
    question = Question.new(prompt: "MC question", question_type: "multiple_choice")
    question.question_options.build(label: "One", value: "one", position: 1)
    question.question_options.build(label: "Two", value: "two", position: 2)

    assert_equal "One\nTwo", question.options_text
  end
end
