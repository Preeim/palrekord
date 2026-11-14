class CreateSeasons < ActiveRecord::Migration[7.1]
  def change
    create_table :seasons do |t|
      t.string :name, limit: 120, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.references :created_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end

    add_index :seasons, :name, unique: true
    add_index :seasons, :starts_at
    add_index :seasons, :ends_at
    add_index :seasons, [ :starts_at, :ends_at ]
  end
end
