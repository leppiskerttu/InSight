require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  setup do
    @survey = surveys(:one)
    @survey.response_sessions.destroy_all
    @survey.questions.destroy_all

    @text_question = @survey.questions.create!(
      prompt: "What should we improve next?",
      question_type: "text",
      position: 1
    )
    @multiple_choice_question = @survey.questions.create!(
      prompt: "Which tool helps most?",
      question_type: "multiple_choice",
      position: 2
    )
    @multiple_choice_question.question_options.create!(
      label: "AI assistant",
      value: "ai_assistant",
      position: 1
    )
    @scale_question = @survey.questions.create!(
      prompt: "How satisfied are you?",
      question_type: "scale",
      position: 3
    )
  end

  test "responses_to_csv includes a header row with question prompts" do
    csv = CSV.parse(@survey.responses_to_csv, headers: true)

    assert_equal [ "Response ID", "Submitted at", @text_question.prompt, @multiple_choice_question.prompt, @scale_question.prompt ],
      csv.headers
  end

  test "responses_to_csv includes one row per response session with formatted answers" do
    session = @survey.response_sessions.create!(submitted_at: Time.zone.parse("2026-07-01 10:00"), respondent_identifier: "test")
    session.answers.create!(question: @text_question, value_text: "Keep it simple")
    session.answers.create!(
      question: @multiple_choice_question,
      value_text: "ai_assistant",
      value_json: { option_label: "AI assistant", option_value: "ai_assistant" }
    )
    session.answers.create!(question: @scale_question, value_number: 4)

    csv = CSV.parse(@survey.responses_to_csv, headers: true)

    assert_equal 1, csv.count
    row = csv.first
    assert_equal session.id.to_s, row["Response ID"]
    assert_equal "2026-07-01 10:00", row["Submitted at"]
    assert_equal "Keep it simple", row[@text_question.prompt]
    assert_equal "AI assistant", row[@multiple_choice_question.prompt]
    assert_equal "4.0", row[@scale_question.prompt]
  end

  test "responses_to_csv leaves unanswered questions blank" do
    session = @survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(question: @text_question, value_text: nil)

    csv = CSV.parse(@survey.responses_to_csv, headers: true)
    row = csv.first

    assert_nil row[@multiple_choice_question.prompt]
    assert_nil row[@scale_question.prompt]
  end

  test "responses_to_csv returns only headers when there are no responses" do
    csv = CSV.parse(@survey.responses_to_csv, headers: true)

    assert_equal 0, csv.count
  end
end
