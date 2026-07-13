class QuestionsController < ApplicationController
  before_action :set_survey
  before_action :set_question, only: %i[show edit update destroy]

  def show
  end

  def new
    @question = @survey.questions.new(question_type: :text)
  end

  def create
    @question = @survey.questions.new(question_params)

    if enhancing_prompt?
      enhance_and_render(:new)
    elsif save_question_with_options(@question)
      redirect_to survey_path(@survey), notice: "Question added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @question.assign_attributes(question_params)

    if enhancing_prompt?
      enhance_and_render(:edit)
    elsif save_question_with_options(@question)
      redirect_to survey_path(@survey), notice: "Question updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to survey_path(@survey), notice: "Question deleted."
  end

  private
    def set_survey
      @survey = Current.user.surveys.find(params[:survey_id])
    end

    def set_question
      @question = @survey.questions.find(params[:id])
    end

    def question_params
      params.require(:question).permit(:prompt, :question_type, :required)
    end

    def enhancing_prompt?
      params[:enhance_prompt].present?
    end

    def enhance_and_render(view)
      result = QuestionEnhancer.call(prompt: @question.prompt, question_type: @question.question_type)
      @question.prompt = result.enhanced_prompt
      @ai_suggestions = result.suggestions
      flash.now[:notice] = "AI improved the question wording (#{result.provider_model})."
      render view
    end

    def save_question_with_options(question)
      option_labels = parsed_option_labels

      if question.multiple_choice? && option_labels.empty?
        question.errors.add(:base, "Multiple choice questions need at least one option.")
        return false
      end

      Question.transaction do
        question.save!
        replace_options!(question, option_labels)
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def parsed_option_labels
      return [] unless params[:question]

      params[:question][:option_list].to_s.lines.map(&:strip).reject(&:blank?)
    end

    def replace_options!(question, option_labels)
      question.question_options.destroy_all

      return unless question.multiple_choice?

      option_labels.each.with_index(1) do |label, position|
        question.question_options.create!(
          label: label,
          value: label.parameterize(separator: "_"),
          position: position
        )
      end
    end
end
