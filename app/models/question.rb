class Question < ApplicationRecord
  belongs_to :survey
  has_many :question_options, -> { order(:position, :id) }, dependent: :destroy
  has_many :answers, dependent: :restrict_with_exception

  enum :question_type, {
    multiple_choice: "multiple_choice",
    scale: "scale",
    text: "text"
  }, validate: true

  attribute :required, :boolean, default: false
  attribute :settings, :json, default: {}

  validates :prompt, presence: true
  validates :position, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :assign_default_position, on: :create

  def options_text
    question_options.map(&:label).join("\n")
  end

  private
    def assign_default_position
      self.position ||= survey.questions.maximum(:position).to_i + 1
    end
end
