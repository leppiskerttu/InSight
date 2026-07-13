require "test_helper"

class GenerateAiReportJobTest < ActiveJob::TestCase
  test "fills in the pending report" do
    survey = User.first.surveys.create!(title: "Job test survey", status: :published)
    question = survey.questions.create!(prompt: "What should we improve?", question_type: "text", position: 1)
    session = survey.response_sessions.create!(submitted_at: Time.current, respondent_identifier: "test")
    session.answers.create!(question: question, value_text: "Need clearer workflow")

    report = survey.ai_reports.create!(status: :pending)

    GenerateAiReportJob.perform_now(report.id)

    assert report.reload.completed?
    assert_equal "local-heuristic", report.provider_model
  end
end
