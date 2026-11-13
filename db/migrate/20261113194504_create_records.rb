class CreateRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :records do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :category, null: false, foreign_key: { on_delete: :cascade }
      t.string :value, limit: 100, null: false
      t.decimal :sort_value, precision: 16, scale: 4, null: false
      t.date :achieved_at, null: false
      t.text :note
      t.string :status, limit: 20, null: false, default: "PENDING"
      t.text :admin_comment
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :records, [ :category_id, :status, :sort_value, :achieved_at ], name: "idx_records_leaderboard"
  end
end
