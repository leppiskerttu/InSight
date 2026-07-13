require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @survey = surveys(:one)
    sign_in_as(@user)

    @survey.response_sessions.destroy_all
    @survey.questions.destroy_all

    @text_question = @survey.questions.create!(
      prompt: "What should we improve next?",
      question_type: "text",
      required: true,
      position: 1
    )
    @multiple_choice_question = @survey.questions.create!(
      prompt: "Which tool helps most?",
      question_type: "multiple_choice",
      required: true,
      position: 2
    )
    @multiple_choice_question.question_options.create!(
      label: "AI assistant",
      value: "ai_assistant",
      position: 1
    )
    @multiple_choice_question.question_options.create!(
      label: "Automated tests",
      value: "automated_tests",
      position: 2
    )
    @scale_question = @survey.questions.create!(
      prompt: "How satisfied are you?",
      question_type: "scale",
      required: false,
      position: 3
    )

    session = @survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(
      question: @text_question,
      value_text: "Keep it simple"
    )
    session.answers.create!(
      question: @multiple_choice_question,
      value_text: "ai_assistant",
      value_json: { option_label: "AI assistant", option_value: "ai_assistant" }
    )
    session.answers.create!(
      question: @scale_question,
      value_number: 4
    )
  end

  test "show displays results summary" do
    get survey_path(@survey)

    assert_response :success
    assert_select "h2", "Results"
    assert_match "Average:", response.body
    assert_match "Keep it simple", response.body
    assert_match "AI assistant", response.body
  end

  test "can queue ai summary generation" do
    assert_difference("AiReport.count", 1) do
      post survey_ai_reports_path(@survey)
    end

    assert_redirected_to survey_path(@survey)
    assert_equal "completed", AiReport.order(:id).last.status
  end

  test "export_responses returns a CSV file of responses" do
    get export_responses_survey_path(@survey, format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type

    csv = CSV.parse(response.body, headers: true)
    assert_equal 1, csv.count
    assert_equal "Keep it simple", csv.first[@text_question.prompt]
    assert_equal "AI assistant", csv.first[@multiple_choice_question.prompt]
  end

  test "export_responses is scoped to the current user's surveys" do
    other_survey = surveys(:two)

    get export_responses_survey_path(other_survey, format: :csv)

    assert_response :not_found
  end
end
