class AddVerificationFieldsToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :recommended_file_type, :string, limit: 20
    add_column :categories, :verification_hint, :string, limit: 255
  end
end
