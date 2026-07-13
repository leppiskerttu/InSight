require "test_helper"

class PublicSurveysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @survey = surveys(:two)
    @survey.publish!
    @text_question = @survey.questions.create!(
      prompt: "Tell us more about your workflow",
      question_type: "text",
      required: true
    )
    @scale_question = @survey.questions.create!(
      prompt: "How satisfied are you?",
      question_type: "scale",
      required: true
    )
    @multiple_choice_question = questions(:two)
    @multiple_choice_question.question_options.create!(
      label: "AI assistant",
      value: "ai_assistant",
      position: 1
    )
  end

  test "show" do
    get public_survey_path(@survey.public_token)

    assert_response :success
    assert_select "h1", @survey.title
  end

  test "creates a response session and answers" do
    assert_difference("ResponseSession.count", 1) do
      assert_difference("Answer.count", 3) do
        post public_survey_responses_path(@survey.public_token), params: {
          answers: {
            @text_question.id.to_s => "This is helpful",
            @scale_question.id.to_s => "4",
            @multiple_choice_question.id.to_s => "ai_assistant"
          }
        }
      end
    end

    assert_redirected_to public_survey_path(@survey.public_token)
    follow_redirect!
    assert_match "Thanks for your response.", response.body
  end

  test "requires answers for required questions" do
    assert_no_difference("ResponseSession.count") do
      post public_survey_responses_path(@survey.public_token), params: {
        answers: {
          @text_question.id.to_s => "",
          @scale_question.id.to_s => "",
          @multiple_choice_question.id.to_s => ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "Please answer all required questions.", response.body
  end

  test "does not accept draft surveys" do
    @survey.update!(status: :draft, published_at: nil)

    get public_survey_path(@survey.public_token)

    assert_response :success
    assert_match "Survey unavailable", response.body
  end
end
