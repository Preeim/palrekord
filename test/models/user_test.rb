require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes username and blank email to nil" do
    user = User.create!(
      username: "  Bence99 ",
      display_name: " Nagy Bence ",
      email: "   ",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_equal "bence99", user.username
    assert_equal "Nagy Bence", user.display_name
    assert_nil user.email
  end

  test "authenticates by username or email" do
    user = User.create!(
      username: "anna98",
      display_name: "Szabó Anna",
      email: "Anna@Example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    assert_equal user, User.authenticate_by_login(" ANNA98 ", "password123")
    assert_equal user, User.authenticate_by_login("anna@example.com", "password123")
    assert_nil User.authenticate_by_login("anna98", "wrongpass")
  end

  test "requires email when email_system setting is true" do
    Setting.set("email_system", "true")
    user = User.new(
      username: "noemail",
      display_name: "Nincs Email",
      email: "",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert user.errors[:email].present?
  end

  test "identifies last_active_admin? accurately" do
    admin1 = User.create!(
      username: "admin_one",
      display_name: "Admin 1",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      is_active: true,
      confirmed_at: Time.current
    )
    assert admin1.last_active_admin?

    inactive_admin = User.create!(
      username: "admin_off",
      display_name: "Admin Off",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      is_active: false,
      confirmed_at: Time.current
    )
    assert admin1.last_active_admin?
    assert_not inactive_admin.last_active_admin?

    admin2 = User.create!(
      username: "admin_two",
      display_name: "Admin 2",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      is_active: true,
      confirmed_at: Time.current
    )
    assert_not admin1.last_active_admin?
    assert_not admin2.last_active_admin?
  end

  test "generates and invalidates email_confirmation and password_reset tokens" do
    user = User.create!(
      username: "tokentest",
      display_name: "Token Teszt",
      email: "token@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    confirm_token = user.generate_token_for(:email_confirmation)
    assert_equal user, User.find_by_token_for(:email_confirmation, confirm_token)

    user.update!(email: "newtoken@example.com")
    assert_nil User.find_by_token_for(:email_confirmation, confirm_token)

    reset_token = user.generate_token_for(:password_reset)
    assert_equal user, User.find_by_token_for(:password_reset, reset_token)

    user.update!(password: "newpassword123", password_confirmation: "newpassword123")
    assert_nil User.find_by_token_for(:password_reset, reset_token)
  end
end
