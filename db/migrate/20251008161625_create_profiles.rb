class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :response, null: false, foreign_key: true, index: { unique: true }
      t.string :unique_token, null: false
      t.integer :viewed_count, default: 0, null: false

      t.timestamps
    end
    add_index :profiles, :unique_token, unique: true
  end
end
