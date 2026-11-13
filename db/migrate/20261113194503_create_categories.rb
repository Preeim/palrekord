class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, limit: 150, null: false
      t.text :description
      t.string :unit, limit: 30, null: false
      t.string :value_type, limit: 20, null: false, default: "DOUBLE"
      t.string :sort_direction, limit: 10, null: false, default: "DESC"
      t.boolean :is_archived, null: false, default: false
      t.references :created_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end

    add_index :categories, :name, unique: true
  end
end
