class CreateResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :responses do |t|
      t.references :questionnaire, null: false, foreign_key: true, index: true
      t.references :employee, foreign_key: true, index: true
      t.string :unique_token, null: false
      t.string :status, default: "draft", null: false
      t.datetime :submitted_at

      t.timestamps
    end
    add_index :responses, :unique_token, unique: true
    add_index :responses, [ :employee_id, :questionnaire_id, :submitted_at ]
    add_index :responses, [ :questionnaire_id, :submitted_at ]
    add_index :responses, [ :questionnaire_id, :status ]
  end
end
