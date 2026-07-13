class Answer < ApplicationRecord
  belongs_to :response_session
  belongs_to :question

  attribute :value_json, :json, default: {}
end
