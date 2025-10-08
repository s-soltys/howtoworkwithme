class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :questionnaire, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end
    add_index :categories, [:questionnaire_id, :name], unique: true
    add_index :categories, [:questionnaire_id, :position]
  end
end
