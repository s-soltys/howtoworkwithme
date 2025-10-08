class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.references :category, null: false, foreign_key: true, index: true
      t.string :question_type, null: false
      t.text :text, null: false
      t.integer :position, null: false
      t.boolean :required, default: true, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end
    add_index :questions, [:category_id, :position]
  end
end
