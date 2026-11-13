class CreateAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments do |t|
      t.references :record, null: false, foreign_key: { on_delete: :cascade }
      t.string :file_type, limit: 20, null: false
      t.string :file_path_or_url, limit: 500
      t.string :original_filename, limit: 255
      t.text :text_content
      t.datetime :uploaded_at, null: false, default: -> { "CURRENT_TIMESTAMP(6)" }

      t.timestamps
    end
  end
end
