class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :home, null: false, foreign_key: true
      t.references :item, foreign_key: true
      t.string :entry_type, null: false
      t.string :title, null: false
      t.date :occurred_on, null: false
      t.text :description
      t.integer :cost_cents
      t.string :contractor_name
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_check_constraint :entries,
      "entry_type IN ('maintenance', 'repair', 'installation', 'replacement', 'inspection', 'purchase', 'note', 'memory')",
      name: "entries_entry_type_check"

    add_check_constraint :entries,
      "cost_cents IS NULL OR cost_cents >= 0",
      name: "entries_cost_cents_check"
  end
end
