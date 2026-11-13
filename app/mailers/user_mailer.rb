class UserMailer < ApplicationMailer
  def email_confirmation(user)
    @user = user
    @token = user.generate_token_for(:email_confirmation)
    @confirmation_url = email_confirmation_url(token: @token)

    mail(to: @user.email, subject: "PálRecord – E-mail cím megerősítése")
  end

  def password_reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    @reset_url = edit_password_reset_url(token: @token)

    mail(to: @user.email, subject: "PálRecord – Jelszó-visszaállítás")
  end
end
