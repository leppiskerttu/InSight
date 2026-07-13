class AiReport < ApplicationRecord
  belongs_to :survey

  enum :status, {
    pending: "pending",
    completed: "completed",
    failed: "failed"
  }, default: :pending, validate: true

  attribute :raw_output, :json, default: {}

  after_update_commit -> {
    broadcast_replace_to survey, target: "ai_summary", partial: "surveys/ai_summary", locals: { survey: survey }
  }
end
