class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :response_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.text :value_text
      t.decimal :value_number
      t.jsonb :value_json, null: false, default: {}

      t.timestamps
    end
  end
end
