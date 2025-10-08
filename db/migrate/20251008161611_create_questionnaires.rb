class CreateQuestionnaires < ActiveRecord::Migration[8.0]
  def change
    create_table :questionnaires do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.text :description
      t.string :unique_token, null: false
      t.datetime :locked_at
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :questionnaires, :unique_token, unique: true
  end
end
