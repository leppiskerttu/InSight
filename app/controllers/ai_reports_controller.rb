class AiReportsController < ApplicationController
  before_action :set_survey

  def create
    GenerateAiReportJob.perform_now(@survey.id)
    redirect_to survey_path(@survey), notice: "AI summary generation started."
  end

  private
    def set_survey
      @survey = Current.user.surveys.find(params[:survey_id])
    end
end
