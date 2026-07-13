class AiReportsController < ApplicationController
  before_action :set_survey

  def create
    report = @survey.ai_reports.create!(status: :pending)
    GenerateAiReportJob.perform_later(report.id)
    redirect_to survey_path(@survey), notice: "AI summary generation started. The page will update automatically when it's ready."
  end

  private
    def set_survey
      @survey = Current.user.surveys.find(params[:survey_id])
    end
end
