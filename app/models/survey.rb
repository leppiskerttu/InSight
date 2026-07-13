class Survey < ApplicationRecord
  belongs_to :user
  has_many :questions, -> { order(:position, :id) }, dependent: :destroy
  has_many :response_sessions, dependent: :destroy
  has_many :ai_reports, dependent: :destroy

  enum :status, {
    draft: "draft",
    published: "published",
    closed: "closed"
  }, default: :draft, validate: true

  before_validation :ensure_public_token, on: :create

  validates :title, presence: true
  validates :public_token, presence: true, uniqueness: true

  scope :recent_first, -> { order(updated_at: :desc) }

  def publish!
    update!(status: :published, published_at: Time.current, closed_at: nil)
  end

  def close!
    update!(status: :closed, closed_at: Time.current)
  end

  def progress_label
    "#{response_sessions.count} responses"
  end

  def accepting_responses?
    published? && closed_at.blank?
  end

  def response_count
    response_sessions.count
  end

  def question_summary(question)
    case question.question_type
    when "multiple_choice"
      answer_counts = question.answers.group(:value_text).count
      question.question_options.map do |option|
        [ option.label, answer_counts[option.value].to_i ]
      end
    when "scale"
      values = question.answers.where.not(value_number: nil).pluck(:value_number)
      {
        average: values.present? ? values.sum.to_f / values.size : nil,
        count: values.size
      }
    else
      question.answers.where.not(value_text: [ nil, "" ]).order(created_at: :desc).limit(5).pluck(:value_text)
    end
  end

  def open_text_answers
    questions.text.flat_map do |question|
      question.answers.where.not(value_text: [ nil, "" ]).order(created_at: :desc).pluck(:value_text).map do |text|
        [ question.prompt, text ]
      end
    end
  end

  def responses_to_csv
    ordered_questions = questions.to_a

    CSV.generate(headers: true) do |csv|
      csv << [ "Response ID", "Submitted at" ] + ordered_questions.map(&:prompt)

      response_sessions.includes(:answers).order(:submitted_at, :id).each do |session|
        answers_by_question_id = session.answers.index_by(&:question_id)

        csv << [ session.id, session.submitted_at&.strftime("%Y-%m-%d %H:%M") ] +
          ordered_questions.map { |question| csv_answer_value(answers_by_question_id[question.id], question) }
      end
    end
  end

  private
    def ensure_public_token
      self.public_token ||= SecureRandom.hex(10)
    end

    def csv_answer_value(answer, question)
      return nil if answer.nil?

      case question.question_type
      when "multiple_choice"
        answer.value_json["option_label"].presence || answer.value_text
      when "scale"
        answer.value_number
      else
        answer.value_text
      end
    end
end
