class CreateHomes < ActiveRecord::Migration[8.1]
  def change
    create_table :homes do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :address
      t.string :home_type

      t.timestamps
    end

    add_check_constraint :homes,
      "home_type IS NULL OR home_type IN ('house', 'condo', 'apartment', 'rental', 'other')",
      name: "homes_home_type_check"
  end
end
