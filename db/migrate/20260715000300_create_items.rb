class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :home, null: false, foreign_key: true
      t.string :item_kind, null: false
      t.string :name, null: false
      t.string :brand
      t.string :model_number
      t.string :serial_number
      t.date :installed_on
      t.text :notes

      t.timestamps
    end

    add_check_constraint :items,
      "item_kind IN ('appliance', 'system')",
      name: "items_item_kind_check"
  end
end
