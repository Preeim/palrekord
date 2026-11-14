require "test_helper"
require "tempfile"
require "fileutils"

class EmailSystemAndAttachmentsFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Setting.ensure_defaults!
    ActionMailer::Base.deliveries.clear

    @admin = User.create!(
      username: "mail_admin",
      display_name: "Mail Admin",
      email: "mail_admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      confirmed_at: Time.current
    )
    @category = Category.create!(
      name: "Maraton",
      unit: "mp",
      value_type: "TIME_DURATION",
      sort_direction: "ASC",
      created_by: @admin
    )
  end

  teardown do
    ActionMailer::Base.deliveries.clear
    FileUtils.rm_rf(Attachment.storage_root)
  end

  test "email_system=true requires email confirmation before login" do
    Setting.set("email_system", "true")
    Setting.set("require_invite_code", "false")

    assert_emails 1 do
      perform_enqueued_jobs do
        post register_path, params: {
          user: {
            username: "ujemailes",
            display_name: "Új E-mailes",
            email: "uj@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end

    assert_redirected_to login_path
    user = User.find_by!(username: "ujemailes")
    assert_not user.confirmed?

    # Cannot log in before confirming email
    post login_path, params: { login: "ujemailes", password: "password123" }
    assert_response :unprocessable_entity
    assert_includes response.body, "erősítsd meg az e-mail címed"

    # Follow confirmation link from email
    mail = ActionMailer::Base.deliveries.last
    token = mail.text_part.body.to_s[/token=([^\s]+)/, 1]
    assert_not_nil token

    get email_confirmation_path(token: token)
    assert_redirected_to login_path
    assert user.reload.confirmed?

    # Now login succeeds
    post login_path, params: { login: "uj@example.com", password: "password123" }
    assert_redirected_to root_path
  end

  test "email_system=true allows self-service password reset and invalidates used token" do
    Setting.set("email_system", "true")
    user = User.create!(
      username: "resetuser",
      display_name: "Reset Réka",
      email: "reka@example.com",
      password: "oldpassword123",
      password_confirmation: "oldpassword123",
      must_change_password: true,
      confirmed_at: Time.current
    )

    assert_emails 1 do
      perform_enqueued_jobs do
        post password_reset_path, params: { email: "REKA@example.com" }
      end
    end
    assert_redirected_to login_path

    mail = ActionMailer::Base.deliveries.last
    token = mail.text_part.body.to_s[/token=([^\s]+)/, 1]
    assert_not_nil token

    get edit_password_reset_path(token: token)
    assert_response :success

    patch password_reset_path(token: token), params: {
      user: { password: "newpassword99", password_confirmation: "newpassword99" }
    }
    assert_redirected_to login_path
    assert_not user.reload.must_change_password?

    # Token is invalid once password is changed
    get edit_password_reset_path(token: token)
    assert_redirected_to new_password_reset_path

    # Can log in with new password
    post login_path, params: { login: "resetuser", password: "newpassword99" }
    assert_redirected_to root_path
  end

  test "email_system=false blocks password reset POST requests" do
    Setting.set("email_system", "false")

    get new_password_reset_path
    assert_response :success

    assert_no_emails do
      post password_reset_path, params: { email: "mail_admin@example.com" }
    end
    assert_redirected_to new_password_reset_path
  end

  test "require_record_approval=false immediately approves submitted record with file attachment" do
    Setting.set("require_record_approval", "false")

    user = User.create!(
      username: "fastuser",
      display_name: "Gyors Gabi",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    post login_path, params: { login: "fastuser", password: "password123" }

    tmp = Tempfile.new([ "medal", ".png" ])
    tmp.binmode
    tmp.write("\x89PNG\r\n\x1a\npng")
    tmp.rewind
    uploaded = Rack::Test::UploadedFile.new(tmp.path, "image/png", original_filename: "medal.png")

    assert_difference([ "Record.count", "Attachment.count" ], 1) do
      post records_path, params: {
        record: {
          category_id: @category.id,
          value: "02:45:10.50",
          achieved_at: Date.current.to_s,
          note: "Hivatalos chipes idő",
          attachments_attributes: {
            "0" => {
              file_type: "IMAGE",
              uploaded_file: uploaded
            }
          }
        }
      }
    end

    record = Record.last
    assert_equal "APPROVED", record.status
    assert_redirected_to category_path(@category)

    attachment = record.attachments.first
    assert_equal "IMAGE", attachment.file_type
    assert_equal "medal.png", attachment.original_filename

    get attachment_path(attachment)
    assert_response :success
  end
end
