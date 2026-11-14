require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      username: "mailertag",
      display_name: "Levél Lajos",
      email: "lajos@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "email_confirmation sends confirmation link with valid token" do
    email = UserMailer.email_confirmation(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "lajos@example.com" ], email.to
    assert_equal "PálRecord – E-mail cím megerősítése", email.subject

    text_body = email.text_part.body.to_s
    html_body = email.html_part.body.to_s

    assert_includes text_body, "Üdvözlünk a PálRecordon, Levél Lajos!"
    assert_includes html_body, "E-mail cím megerősítése"
    assert_includes text_body, "/email_confirmation?token="

    token = text_body[/token=([^\s]+)/, 1]
    assert_not_nil token
    assert_equal @user, User.find_by_token_for(:email_confirmation, token)
  end

  test "password_reset sends reset link with valid token" do
    email = UserMailer.password_reset(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "lajos@example.com" ], email.to
    assert_equal "PálRecord – Jelszó-visszaállítás", email.subject

    text_body = email.text_part.body.to_s
    html_body = email.html_part.body.to_s

    assert_includes text_body, "Szia Levél Lajos!"
    assert_includes html_body, "Új jelszó beállítása"
    assert_includes text_body, "/password_reset/edit?token="

    token = text_body[/token=([^\s]+)/, 1]
    assert_not_nil token
    assert_equal @user, User.find_by_token_for(:password_reset, token)
  end
end
