class ResponseSession < ApplicationRecord
  belongs_to :survey
  has_many :answers, dependent: :destroy

  attribute :metadata, :json, default: {}
end
