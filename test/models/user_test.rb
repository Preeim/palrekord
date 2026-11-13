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
end
