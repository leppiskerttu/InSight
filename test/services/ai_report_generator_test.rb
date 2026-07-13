require "test_helper"

class AiReportGeneratorTest < ActiveSupport::TestCase
  test "generates a completed report from open-ended answers" do
    survey = User.first.surveys.create!(title: "AI test survey", status: :published)

    question = survey.questions.create!(
      prompt: "What should we improve?",
      question_type: "text",
      required: true,
      position: 1
    )

    session = survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(question: question, value_text: "Need clearer workflow and better automation")

    report = AiReportGenerator.call(survey)

    assert report.completed?
    assert_match "Executive summary", report.summary_markdown
    assert_equal "local-heuristic", report.provider_model
    assert_includes report.raw_output["themes"].join(" "), "workflow"
  end

  test "falls back to the heuristic provider when the configured LLM provider fails" do
    survey = User.first.surveys.create!(title: "Fallback survey", status: :published)

    question = survey.questions.create!(
      prompt: "What should we improve?",
      question_type: "text",
      required: true,
      position: 1
    )

    session = survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(question: question, value_text: "Need clearer workflow and better automation")

    failing_provider = Class.new do
      def available?
        true
      end

      def model
        "flaky-provider"
      end

      def call(**)
        raise "boom"
      end
    end.new

    report = AiReportGenerator.new(survey, provider: failing_provider).call

    assert report.completed?
    assert_equal "local-heuristic", report.provider_model
    assert_match "Executive summary", report.summary_markdown
  end

  test "uses the LLM provider when it is available and succeeds" do
    survey = User.first.surveys.create!(title: "LLM survey", status: :published)

    question = survey.questions.create!(
      prompt: "What should we improve?",
      question_type: "text",
      required: true,
      position: 1
    )

    session = survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(question: question, value_text: "Need clearer workflow")

    fake_result = AiSummary::Result.new(
      provider_model: "claude-test",
      summary_markdown: "## Executive summary\nAll good.",
      raw_output: { themes: [ "Workflow clarity" ], sentiment: "mixed" }
    )

    succeeding_provider = Class.new do
      def available?
        true
      end

      def model
        "claude-test"
      end

      def call(**)
        @result
      end

      def with_result(result)
        @result = result
        self
      end
    end.new.with_result(fake_result)

    report = AiReportGenerator.new(survey, provider: succeeding_provider).call

    assert report.completed?
    assert_equal "claude-test", report.provider_model
    assert_match "All good.", report.summary_markdown
  end
end
