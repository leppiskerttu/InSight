class GenerateAiReportJob < ApplicationJob
  queue_as :default

  def perform(survey_id)
    survey = Survey.find(survey_id)
    AiReportGenerator.call(survey)
  end
end
