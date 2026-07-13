class SurveysController < ApplicationController
  before_action :set_survey, only: %i[show edit update publish close]

  def index
    @surveys = Current.user.surveys.recent_first
  end

  def show
    @questions = @survey.questions.includes(:question_options, :answers)
  end

  def new
    @survey = Current.user.surveys.new
  end

  def create
    @survey = Current.user.surveys.new(survey_params)

    if @survey.save
      redirect_to @survey, notice: "Survey created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @survey.update(survey_params)
      redirect_to @survey, notice: "Survey updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @survey.publish!
    redirect_to @survey, notice: "Survey published."
  end

  def close
    @survey.close!
    redirect_to @survey, notice: "Survey closed."
  end

  private
    def set_survey
      @survey = Current.user.surveys.find(params[:id])
    end

    def survey_params
      params.require(:survey).permit(:title, :description)
    end
end
