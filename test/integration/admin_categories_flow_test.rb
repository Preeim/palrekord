require "test_helper"

class AdminCategoriesFlowTest < ActionDispatch::IntegrationTest
  setup do
    Setting.ensure_defaults!

    @admin = User.create!(
      username: "cat_admin",
      display_name: "Kategória Admin",
      email: "cat_admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      confirmed_at: Time.current
    )

    @member = User.create!(
      username: "cat_member",
      display_name: "Teszt Tag",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    @existing_category = Category.create!(
      name: "Húzódzkodás",
      unit: "db",
      value_type: "INT",
      sort_direction: "DESC",
      recommended_file_type: "LINK",
      verification_hint: "Vágatlan videó",
      created_by: @admin
    )

    @archived_category = Category.create!(
      name: "Régi verseny",
      unit: "mp",
      value_type: "DOUBLE",
      sort_direction: "ASC",
      is_archived: true,
      created_by: @admin
    )

    @record = Record.create!(
      user: @member,
      category: @existing_category,
      value: "18",
      achieved_at: Date.current,
      status: "APPROVED"
    )
  end

  test "admin can view, filter, create, edit, archive, restore, and delete categories" do
    post login_path, params: { login: "cat_admin", password: "password123" }
    assert_redirected_to root_path

    # Index shows both active and archived by default
    get admin_categories_path
    assert_response :success
    assert_includes response.body, "Húzódzkodás"
    assert_includes response.body, "Régi verseny"

    # Active filter
    get admin_categories_path(status: "ACTIVE")
    assert_response :success
    assert_includes response.body, "Húzódzkodás"
    assert_not_includes response.body, "Régi verseny"

    # Archived filter
    get admin_categories_path(status: "ARCHIVED")
    assert_response :success
    assert_includes response.body, "Régi verseny"
    assert_not_includes response.body, "Húzódzkodás"

    # Create new category from admin panel
    assert_difference("Category.count", 1) do
      post admin_categories_path, params: {
        category: {
          name: "Maratoni futás",
          unit: "perc",
          value_type: "TIME_DURATION",
          sort_direction: "ASC",
          recommended_file_type: "LINK",
          verification_hint: "Strava link",
          description: "42.2 km táv"
        }
      }
    end
    assert_redirected_to admin_categories_path

    created = Category.find_by!(name: "Maratoni futás")
    assert_equal @admin.id, created.created_by_id
    assert_not created.is_archived?

    # Invalid create re-renders index with 422
    assert_no_difference("Category.count") do
      post admin_categories_path, params: {
        category: {
          name: "",
          unit: "db",
          value_type: "INT",
          sort_direction: "DESC"
        }
      }
    end
    assert_response :unprocessable_entity

    # Edit page and update
    get edit_admin_category_path(@existing_category, return_status: "ACTIVE")
    assert_response :success

    patch admin_category_path(@existing_category, return_status: "ACTIVE"), params: {
      category: {
        name: "Súlyozott húzódzkodás",
        unit: "db",
        value_type: "INT",
        sort_direction: "DESC",
        verification_hint: "Teljes ismétlésszám látható"
      }
    }
    assert_redirected_to admin_categories_path(status: "ACTIVE")
    assert_equal "Súlyozott húzódzkodás", @existing_category.reload.name

    # Quick archive and restore
    patch admin_category_path(@existing_category, return_status: "ALL"), params: {
      category: { is_archived: true }
    }
    assert_redirected_to admin_categories_path(status: "ALL")
    assert @existing_category.reload.is_archived?

    patch admin_category_path(@existing_category, return_status: "ALL"), params: {
      category: { is_archived: false }
    }
    assert_redirected_to admin_categories_path(status: "ALL")
    assert_not @existing_category.reload.is_archived?

    # Delete category along with associated records
    assert_difference("Category.count", -1) do
      assert_difference("Record.count", -1) do
        delete admin_category_path(@existing_category, return_status: "ALL")
      end
    end
    assert_redirected_to admin_categories_path(status: "ALL")
    assert_nil Record.find_by(id: @record.id)
  end
end
