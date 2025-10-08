class CreateAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :answers do |t|
      t.references :response, null: false, foreign_key: true, index: true
      t.references :question, null: false, foreign_key: true, index: true
      t.text :text_value
      t.integer :selected_option_id
      t.integer :selected_option_ids, array: true, default: []
      t.boolean :boolean_value

      t.timestamps
    end
    add_index :answers, [:response_id, :question_id], unique: true
    add_index :answers, :selected_option_ids, using: :gin
  end
end
