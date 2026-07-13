class PublicSurveysController < ApplicationController
  allow_unauthenticated_access
  before_action :set_survey

  def show
    @response_session = @survey.response_sessions.new
  end

  def create_response
    @response_session = @survey.response_sessions.new(
      submitted_at: Time.current,
      respondent_identifier: request.remote_ip,
      metadata: {
        user_agent: request.user_agent
      }
    )

    if !@survey.accepting_responses?
      redirect_to public_survey_path(@survey.public_token), alert: "This survey is not accepting responses."
      return
    end

    if invalid_questions.any?
      flash.now[:alert] = "Please answer all required questions."
      render :show, status: :unprocessable_entity
      return
    end

    ResponseSession.transaction do
      @response_session.save!
      build_answers.each(&:save!)
    end

    redirect_to public_survey_path(@survey.public_token), notice: "Thanks for your response."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "We could not save your response. Please review the form and try again."
    render :show, status: :unprocessable_entity
  end

  private
    def set_survey
      @survey = Survey.includes(questions: :question_options).find_by!(public_token: params[:token])
    end

    def answer_params
      params.fetch(:answers, {}).to_unsafe_h
    end

    def invalid_questions
      @invalid_questions ||= @survey.questions.select do |question|
        question.required? && normalized_answer_for(question).blank?
      end
    end

    def build_answers
      @survey.questions.map do |question|
        value = normalized_answer_for(question)

        @response_session.answers.new(
          question: question,
          value_text: value_text_for(question, value),
          value_number: value_number_for(question, value),
          value_json: value_json_for(question, value)
        )
      end
    end

    def normalized_answer_for(question)
      value = answer_params[question.id.to_s]
      value.is_a?(String) ? value.strip : value
    end

    def value_text_for(question, value)
      return value if question.text? || question.multiple_choice?

      nil
    end

    def value_number_for(question, value)
      return value if question.scale? && value.present?

      nil
    end

    def value_json_for(question, value)
      return {} if value.blank?

      if question.multiple_choice?
        selected_option = question.question_options.find { |option| option.value == value }
        return { option_label: selected_option&.label, option_value: value }
      end

      {}
    end
end
