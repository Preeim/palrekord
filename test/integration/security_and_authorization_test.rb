require "test_helper"
require "tempfile"
require "fileutils"

class SecurityAndAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Setting.ensure_defaults!

    @admin = User.create!(
      username: "sec_admin",
      display_name: "Biztonsági Admin",
      email: "sec_admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      confirmed_at: Time.current
    )

    @tag1 = User.create!(
      username: "tag_one",
      display_name: "Első Tag",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    @tag2 = User.create!(
      username: "tag_two",
      display_name: "Második Tag",
      password: "password123",
      password_confirmation: "password123",
      role: "TAG",
      confirmed_at: Time.current
    )

    @category = Category.create!(
      name: "Fekvenyomás",
      unit: "kg",
      value_type: "DOUBLE",
      sort_direction: "DESC",
      created_by: @admin
    )

    @pending_record = Record.create!(
      user: @tag1,
      category: @category,
      value: "95",
      achieved_at: Date.current,
      status: "PENDING"
    )

    @approved_record = Record.create!(
      user: @tag1,
      category: @category,
      value: "100",
      achieved_at: Date.current,
      status: "APPROVED"
    )
  end

  teardown do
    FileUtils.rm_rf(Attachment.storage_root)
  end

  test "guests and TAG users are blocked from all admin endpoints" do
    [ admin_records_path, admin_categories_path, admin_users_path, admin_invite_codes_path, admin_seasons_path, admin_settings_path ].each do |path|
      get path
      assert_redirected_to login_path
    end

    post login_path, params: { login: "tag_one", password: "password123" }
    assert_redirected_to root_path

    [ admin_records_path, admin_categories_path, admin_users_path, admin_invite_codes_path, admin_seasons_path, admin_settings_path ].each do |path|
      get path
      assert_redirected_to root_path
    end

    post admin_categories_path, params: { category: { name: "Jogosulatlan", unit: "db", value_type: "INT", sort_direction: "DESC" } }
    assert_redirected_to root_path

    patch admin_category_path(@category), params: { category: { is_archived: true } }
    assert_redirected_to root_path
    assert_not @category.reload.is_archived?

    assert_no_difference("Category.count") do
      delete admin_category_path(@category)
      assert_redirected_to root_path
    end

    post admin_invite_codes_path, params: { invite_code: { label: "Hack" } }
    assert_redirected_to root_path

    patch admin_record_path(@pending_record), params: { record: { status: "APPROVED" } }
    assert_redirected_to root_path
    assert_equal "PENDING", @pending_record.reload.status

    get edit_category_path(@category)
    assert_redirected_to root_path
  end

  test "TAG can edit and destroy own PENDING record only, not APPROVED or others records" do
    post login_path, params: { login: "tag_one", password: "password123" }

    # Own PENDING record is editable and deletable
    get edit_record_path(@pending_record)
    assert_response :success

    patch record_path(@pending_record), params: { record: { value: "97.5" } }
    assert_redirected_to profile_path
    assert_equal "97.5", @pending_record.reload.value

    # Own APPROVED record cannot be edited or destroyed by TAG
    get edit_record_path(@approved_record)
    assert_redirected_to profile_path

    assert_no_difference("Record.count") do
      patch record_path(@approved_record), params: { record: { value: "150" } }
      assert_redirected_to profile_path
      delete record_path(@approved_record)
      assert_redirected_to profile_path
    end
    assert_equal "100", @approved_record.reload.value

    # Other user cannot edit/delete @pending_record
    delete logout_path
    post login_path, params: { login: "tag_two", password: "password123" }

    get edit_record_path(@pending_record)
    assert_redirected_to profile_path

    assert_no_difference("Record.count") do
      delete record_path(@pending_record)
      assert_redirected_to profile_path
    end

    # Owner can delete own PENDING record
    delete logout_path
    post login_path, params: { login: "tag_one", password: "password123" }
    assert_difference("Record.count", -1) do
      delete record_path(@pending_record)
    end
    assert_redirected_to profile_path
  end

  test "protects last active admin and allows admin to reset password or suspend other users" do
    post login_path, params: { login: "sec_admin", password: "password123" }

    # Last active admin cannot demote, deactivate, or delete self
    patch admin_user_path(@admin), params: { user: { role: "TAG" } }
    assert_redirected_to admin_users_path
    assert_equal "ADMIN", @admin.reload.role

    patch admin_user_path(@admin), params: { user: { is_active: false } }
    assert_redirected_to admin_users_path
    assert @admin.reload.is_active?

    assert_no_difference("User.count") do
      delete admin_user_path(@admin)
    end
    assert_redirected_to admin_users_path

    # Admin can generate temporary password for TAG user
    post reset_password_admin_user_path(@tag2)
    assert_redirected_to admin_users_path
    assert @tag2.reload.must_change_password?
    temp_pass = flash[:temp_password_value]
    assert temp_pass.present?

    # Admin can suspend and reactivate TAG user
    patch admin_user_path(@tag1), params: { user: { is_active: false } }
    assert_redirected_to admin_users_path
    assert_not @tag1.reload.is_active?
  end

  test "suspended user cannot log in and active session is invalidated upon suspension" do
    post login_path, params: { login: "tag_one", password: "password123" }
    get profile_path
    assert_response :success

    @tag1.update!(is_active: false)

    # Next request clears session and rejects access
    get profile_path
    assert_redirected_to login_path

    # Subsequent login attempt is blocked
    post login_path, params: { login: "tag_one", password: "password123" }
    assert_response :unprocessable_entity
    assert_includes response.body, "A fiókod fel van függesztve."
  end

  test "attachments controller enforces visibility rules for pending and private records" do
    pending_att = Attachment.create!(
      record: @pending_record,
      file_type: "IMAGE",
      uploaded_file: build_png("pending_proof.png")
    )
    approved_att = Attachment.create!(
      record: @approved_record,
      file_type: "IMAGE",
      uploaded_file: build_png("approved_proof.png")
    )

    # Guest can download APPROVED attachment when public_leaderboards is true
    get attachment_path(approved_att)
    assert_response :success

    # Guest cannot download PENDING attachment
    get attachment_path(pending_att)
    assert_redirected_to login_path

    # Another TAG cannot download @tag1's PENDING attachment
    post login_path, params: { login: "tag_two", password: "password123" }
    get attachment_path(pending_att)
    assert_redirected_to login_path

    # Owner CAN download own PENDING attachment
    delete logout_path
    post login_path, params: { login: "tag_one", password: "password123" }
    get attachment_path(pending_att)
    assert_response :success

    # Admin CAN download any PENDING attachment
    delete logout_path
    post login_path, params: { login: "sec_admin", password: "password123" }
    get attachment_path(pending_att)
    assert_response :success

    # When public_leaderboards is false, guest cannot download APPROVED attachment either
    delete logout_path
    Setting.set("public_leaderboards", "false")
    get attachment_path(approved_att)
    assert_redirected_to login_path
  end

  private

  def build_png(filename)
    tmp = Tempfile.new([ File.basename(filename, ".*"), ".png" ])
    tmp.binmode
    tmp.write("\x89PNG\r\n\x1a\nfake")
    tmp.rewind
    Rack::Test::UploadedFile.new(tmp.path, "image/png", original_filename: filename)
  end
end
