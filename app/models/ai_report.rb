class AiReport < ApplicationRecord
  belongs_to :survey

  enum :status, {
    pending: "pending",
    completed: "completed",
    failed: "failed"
  }, default: :pending, validate: true

  attribute :raw_output, :json, default: {}
end
