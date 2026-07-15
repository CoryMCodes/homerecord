class AddEntryItemHomeForeignKey < ActiveRecord::Migration[8.1]
  def change
    add_index :items, [ :id, :home_id ], unique: true
    add_foreign_key :entries,
      :items,
      column: [ :item_id, :home_id ],
      primary_key: [ :id, :home_id ],
      name: "fk_entries_item_home"
  end
end
