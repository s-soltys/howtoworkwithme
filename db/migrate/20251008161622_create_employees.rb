class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :email

      t.timestamps
    end
  end
end
