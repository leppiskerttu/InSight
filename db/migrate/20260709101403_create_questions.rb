class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :survey, null: false, foreign_key: true
      t.text :prompt, null: false
      t.string :question_type, null: false
      t.boolean :required, null: false, default: false
      t.integer :position
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end
  end
end
