require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @survey = surveys(:one)
    @question = questions(:one)
    sign_in_as(@user)
  end

  test "new" do
    get new_survey_question_path(@survey)
    assert_response :success
  end

  test "create text question" do
    assert_difference("Question.count", 1) do
      post survey_questions_path(@survey), params: {
        question: {
          prompt: "What should we improve next?",
          question_type: "text",
          required: "1"
        }
      }
    end

    assert_redirected_to survey_path(@survey)
    assert_equal "What should we improve next?", Question.order(:id).last.prompt
  end

  test "create multiple choice question with options" do
    assert_difference("Question.count", 1) do
      post survey_questions_path(@survey), params: {
        question: {
          prompt: "Which tool do you use most?",
          question_type: "multiple_choice",
          required: "0",
          option_list: "GitHub Copilot\nClaude Code\nCursor"
        }
      }
    end

    created_question = Question.order(:id).last

    assert_equal 3, created_question.question_options.count
    assert_redirected_to survey_path(@survey)
  end

  test "rejects multiple choice question without options" do
    assert_no_difference("Question.count") do
      post survey_questions_path(@survey), params: {
        question: {
          prompt: "Which tool do you use most?",
          question_type: "multiple_choice",
          required: "0",
          option_list: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update question" do
    patch survey_question_path(@survey, @question), params: {
      question: {
        prompt: "Updated prompt",
        question_type: "text",
        required: "0"
      }
    }

    assert_redirected_to survey_path(@survey)
    assert_equal "Updated prompt", @question.reload.prompt
  end

  test "destroy question" do
    question = @survey.questions.create!(
      prompt: "Disposable question",
      question_type: "text",
      required: false
    )

    assert_difference("Question.count", -1) do
      delete survey_question_path(@survey, question)
    end

    assert_redirected_to survey_path(@survey)
  end
end
