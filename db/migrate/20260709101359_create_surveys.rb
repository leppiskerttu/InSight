class CreateSurveys < ActiveRecord::Migration[8.1]
  def change
    create_table :surveys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.string :public_token, null: false
      t.datetime :published_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :surveys, :public_token, unique: true
  end
end
