class CreateQuestionOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :question_options do |t|
      t.references :question, null: false, foreign_key: true
      t.string :label, null: false
      t.string :value, null: false
      t.integer :position

      t.timestamps
    end
  end
end
