class QuestionOption < ApplicationRecord
  belongs_to :question

  validates :label, :value, presence: true
end
