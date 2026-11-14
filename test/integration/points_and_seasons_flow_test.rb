require "test_helper"

class PointsAndSeasonsFlowTest < ActionDispatch::IntegrationTest
  setup do
    Setting.ensure_defaults!
    Setting.set("members_can_create_categories", "true")
    Setting.set("monthly_category_limit", "2")

    @admin = User.create!(
      username: "admin1",
      display_name: "Adminisztrátor",
      email: "admin1@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      confirmed_at: Time.current
    )

    @tag = User.create!(
      username: "bence",
      display_name: "Nagy Bence",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    @peti = User.create!(
      username: "peti",
      display_name: "Kovács Peti",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    @season = Season.create!(
      name: "2026 Őszi Szezon",
      starts_at: 10.days.ago,
      ends_at: 20.days.from_now,
      created_by: @admin
    )

    @past_category = Category.create!(
      name: "Fekvenyomás max",
      unit: "kg",
      value_type: "DOUBLE",
      sort_direction: "DESC",
      created_by: @tag,
      created_at: 2.months.ago
    )

    @season_category = Category.create!(
      name: "100m sörfutás",
      unit: "mp",
      value_type: "TIME_DURATION",
      sort_direction: "ASC",
      created_by: @admin,
      created_at: 1.day.ago
    )

    Record.create!(user: @peti, category: @season_category, value: "18.42", achieved_at: Date.current, status: "APPROVED", created_at: 2.days.ago)
    Record.create!(user: @tag, category: @season_category, value: "19.05", achieved_at: Date.current, status: "APPROVED", created_at: 1.day.ago)
    Record.create!(user: @tag, category: @season_category, value: "20.10", achieved_at: Date.current, status: "APPROVED", created_at: 3.days.ago)
    Record.create!(user: @tag, category: @past_category, value: "125.0", achieved_at: Date.current, status: "APPROVED", created_at: 1.day.ago)
  end

  test "homepage, category page, and profile display points, ties, secondary attempts, and seasons" do
    post login_path, params: { login: "bence", password: "password123" }
    assert_redirected_to root_path

    # Overall: @tag has 1 pt (2nd/2 in season_category) + 1 pt (1st/1 in past_category) = 2 pt
    # @peti has 2 pt (1st/2 in season_category)
    get root_path
    assert_response :success
    assert_includes response.body, "Nagy Bence · <strong>2 pt</strong>"
    assert_includes response.body, "Kvóta: 2/2"
    assert_includes response.body, "2026 Őszi Szezon"
    assert_includes response.body, "2 fő (max <strong>2 pt</strong>)"
    assert_includes response.body, "Nagy Bence (Te)"

    # Switch to season tab
    get root_path(tab: "season", season_id: @season.id)
    assert_response :success
    assert_includes response.body, "Kovács Peti"
    assert_includes response.body, "2 pt"
    assert_includes response.body, "1 pt"

    # Category page shows points and secondary personal attempt
    get category_path(@season_category)
    assert_response :success
    assert_includes response.body, "+2 pt"
    assert_includes response.body, "+1 pt"
    assert_includes response.body, "Nagy Bence (korábbi kísérlet)"
    assert_includes response.body, "0 pt"

    # Profile page shows 3 summary cards and breakdown
    get profile_path
    assert_response :success
    assert_includes response.body, "ÖRÖKÖS ÉLŐ PONTSZÁM"
    assert_includes response.body, "2 pont"
    assert_includes response.body, "2026 ŐSZI SZEZON (AKTÍV)"
    assert_includes response.body, "1 pont"
    assert_includes response.body, "2 / 2 szabad"
    assert_includes response.body, "Pontjaim tételes lebontása"
  end

  test "enforces monthly category quota for TAG users while exempting ADMIN and past-month categories" do
    post login_path, params: { login: "bence", password: "password123" }
    assert_redirected_to root_path

    # @past_category was created 2 months ago, so @tag still has 2/2 quota this month
    assert_difference("Category.count", 2) do
      post categories_path, params: {
        category: { name: "Új szám 1", unit: "db", value_type: "INT", sort_direction: "DESC" }
      }
      assert_redirected_to category_path(Category.last)

      post categories_path, params: {
        category: { name: "Új szám 2", unit: "db", value_type: "INT", sort_direction: "DESC" }
      }
      assert_redirected_to category_path(Category.last)
    end

    assert_equal 0, @tag.reload.remaining_category_quota

    get root_path
    assert_response :success
    assert_includes response.body, "0 / 2 elérhető ebben a hónapban"

    get new_category_path
    assert_response :success
    assert_includes response.body, "0 / 2 elérhető ebben a hónapban"

    # 3rd category in same month is blocked
    assert_no_difference("Category.count") do
      post categories_path, params: {
        category: { name: "Új szám 3", unit: "db", value_type: "INT", sort_direction: "DESC" }
      }
    end
    assert_response :unprocessable_entity

    # Admin can always create categories and can raise monthly_category_limit
    delete logout_path
    post login_path, params: { login: "admin1", password: "password123" }
    assert_redirected_to root_path

    assert_difference("Category.count", 1) do
      post categories_path, params: {
        category: { name: "Admin szám", unit: "db", value_type: "INT", sort_direction: "DESC" }
      }
    end
    assert_redirected_to category_path(Category.last)

    limit_setting = Setting.find_by!(key: "monthly_category_limit")
    patch admin_setting_path(limit_setting), params: { setting: { value: "3" } }
    assert_redirected_to admin_settings_path
    assert_equal 3, Setting.monthly_category_limit
    assert_equal 1, @tag.reload.remaining_category_quota
  end

  test "admin can create, edit, and delete seasons" do
    post login_path, params: { login: "admin1", password: "password123" }
    assert_redirected_to root_path

    get admin_seasons_path
    assert_response :success

    assert_difference("Season.count", 1) do
      post admin_seasons_path, params: {
        season: {
          name: "2027 Téli Szezon",
          starts_at: "2027-01-01T00:00",
          ends_at: "2027-02-28T23:59"
        }
      }
    end
    assert_redirected_to admin_seasons_path

    season = Season.find_by!(name: "2027 Téli Szezon")
    get edit_admin_season_path(season)
    assert_response :success

    patch admin_season_path(season), params: {
      season: { name: "2027 Téli Kupa" }
    }
    assert_redirected_to admin_seasons_path
    assert_equal "2027 Téli Kupa", season.reload.name

    assert_difference("Season.count", -1) do
      delete admin_season_path(season)
    end
    assert_redirected_to admin_seasons_path
  end
end
