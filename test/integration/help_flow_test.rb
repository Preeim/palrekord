require "test_helper"

class HelpFlowTest < ActionDispatch::IntegrationTest
  setup do
    Setting.ensure_defaults!
    @user = User.create!(
      username: "sugoteszt",
      display_name: "Súgó Teszt",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      is_active: true,
      confirmed_at: Time.current
    )
  end

  test "guest can access help page even when public_leaderboards is disabled" do
    Setting.set("public_leaderboards", "false")

    get help_path
    assert_response :success
    assert_select "header nav a[href=?]", help_path, text: "Súgó"
    assert_select "footer a[href=?]", help_path
    assert_select "h1.page-title", text: /Súgó/
    assert_select "img.help-diagram", count: 4
    assert_match(/help_home/, response.body)
    assert_match(/help_auth/, response.body)
    assert_match(/help_record_verification/, response.body)
    assert_match(/help_points_profile/, response.body)
  end

  test "logged in user can access help page and see live settings" do
    Setting.set("monthly_category_limit", "4")
    Setting.set("members_can_create_categories", "true")

    post login_path, params: { login: "sugoteszt", password: "password123" }
    assert_redirected_to root_path

    get help_path
    assert_response :success
    assert_select "header nav a[href=?]", help_path, text: "Súgó"
    assert_match(/havi 4 db/, response.body)
  end

  test "user with must_change_password can still access help page" do
    @user.update!(must_change_password: true)

    post login_path, params: { login: "sugoteszt", password: "password123" }
    assert_redirected_to profile_path

    get root_path
    assert_redirected_to profile_path

    get help_path
    assert_response :success
    assert_select "h1.page-title", text: /Súgó/
  end
end
