class CreateAiReports < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_reports do |t|
      t.references :survey, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :provider_model
      t.text :summary_markdown
      t.jsonb :raw_output, null: false, default: {}
      t.datetime :generated_at

      t.timestamps
    end
  end
end
