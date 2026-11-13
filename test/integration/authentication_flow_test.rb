require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    Setting.ensure_defaults!
    @admin = User.create!(
      username: "adminuser",
      display_name: "Fő Admin",
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      is_active: true,
      confirmed_at: Time.current
    )
    @invite = InviteCode.create!(
      code: "PAL-TEST01",
      max_uses: 1,
      is_active: true,
      created_by: @admin
    )
    @category = Category.create!(
      name: "100m sörfutás",
      unit: "mp",
      value_type: "TIME_DURATION",
      sort_direction: "ASC",
      created_by: @admin
    )
  end

  test "registration requires valid invite code when enabled and increments uses_count" do
    post register_path, params: {
      invite_code: "WRONG-CODE",
      user: {
        username: "ujtag",
        display_name: "Új Tag",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_response :unprocessable_entity
    assert_nil User.find_by(username: "ujtag")

    assert_difference("User.count", 1) do
      post register_path, params: {
        invite_code: "pal-test01",
        user: {
          username: "ujtag",
          display_name: "Új Tag",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_path
    new_user = User.find_by!(username: "ujtag")
    assert_equal "TAG", new_user.role
    assert_equal @invite.id, new_user.invite_code_id
    assert_equal 1, @invite.reload.uses_count
    assert_not @invite.usable?
  end

  test "public_leaderboards setting controls guest access to homepage" do
    get root_path
    assert_response :success

    Setting.set("public_leaderboards", "false")
    get root_path
    assert_redirected_to login_path
  end

  test "member submits pending record and admin approves it" do
    tag = User.create!(
      username: "peti",
      display_name: "Kovács Peti",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    post login_path, params: { login: "peti", password: "password123" }
    assert_redirected_to root_path

    # Tag cannot create category while members_can_create_categories is false
    get new_category_path
    assert_redirected_to root_path

    # Tag submits record (PENDING)
    post records_path, params: {
      record: {
        category_id: @category.id,
        value: "18.42",
        achieved_at: Date.current.to_s,
        note: "Tanúval mérve"
      }
    }
    assert_redirected_to profile_path
    record = Record.last
    assert_equal "PENDING", record.status

    delete logout_path
    post login_path, params: { login: "adminuser", password: "password123" }
    assert_redirected_to root_path

    patch admin_record_path(record), params: {
      record: { status: "APPROVED", admin_comment: "Rendben" }
    }
    assert_redirected_to admin_records_path(status: "PENDING")
    assert_equal "APPROVED", record.reload.status
    assert_equal @admin.id, record.reviewed_by_id
  end

  test "must_change_password forces redirect to profile until updated" do
    tag = User.create!(
      username: "tempuser",
      display_name: "Temp User",
      password: "temppassword1",
      password_confirmation: "temppassword1",
      must_change_password: true,
      confirmed_at: Time.current
    )

    post login_path, params: { login: "tempuser", password: "temppassword1" }
    assert_redirected_to profile_path

    get root_path
    assert_redirected_to profile_path

    patch profile_password_path, params: {
      current_password: "temppassword1",
      password: "newpassword123",
      password_confirmation: "newpassword123"
    }
    assert_redirected_to profile_path
    assert_not tag.reload.must_change_password?

    get root_path
    assert_response :success
  end
end
