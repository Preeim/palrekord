class CreateUsersAndInviteCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :username, limit: 50, null: false
      t.string :display_name, limit: 100, null: false
      t.string :email, limit: 255
      t.string :password_digest, limit: 255, null: false
      t.string :role, limit: 20, null: false, default: "TAG"
      t.boolean :is_active, null: false, default: true
      t.boolean :must_change_password, null: false, default: false
      t.datetime :confirmed_at
      t.datetime :last_login_at
      t.bigint :invite_code_id

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
    add_index :users, :invite_code_id

    create_table :invite_codes do |t|
      t.string :code, limit: 64, null: false
      t.string :label, limit: 100
      t.integer :max_uses
      t.integer :uses_count, null: false, default: 0
      t.datetime :expires_at
      t.boolean :is_active, null: false, default: true
      t.references :created_by, null: true, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end

    add_index :invite_codes, :code, unique: true
    add_foreign_key :users, :invite_codes, column: :invite_code_id, on_delete: :nullify
  end
end
