class AddValueFieldsToAnswers < ActiveRecord::Migration[8.0]
  def change
    # For slider, character sheet numeric values
    add_column :answers, :numeric_value, :integer

    # For complex data: card rankings, energy maps, character sheets
    add_column :answers, :jsonb_value, :jsonb, default: {}

    # Add index for JSONB queries (GIN index for efficient nested queries)
    add_index :answers, :jsonb_value, using: :gin
  end
end
