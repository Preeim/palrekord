class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.string :key, limit: 100, null: false
      t.string :value, limit: 255, null: false
      t.string :description, limit: 255

      t.timestamps
    end

    add_index :settings, :key, unique: true
  end
end
