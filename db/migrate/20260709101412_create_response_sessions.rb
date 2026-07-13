class CreateResponseSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :response_sessions do |t|
      t.references :survey, null: false, foreign_key: true
      t.datetime :submitted_at
      t.string :respondent_identifier
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
  end
end
