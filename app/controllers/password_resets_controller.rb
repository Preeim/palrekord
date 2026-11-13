class PasswordResetsController < ApplicationController
  before_action :ensure_email_system_enabled, only: [ :create, :edit, :update ]
  before_action :load_user_by_token, only: [ :edit, :update ]

  def new
    @email_system = Setting.email_system?
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email) if email.present?

    if user&.is_active?
      UserMailer.password_reset(user).deliver_later
    end

    redirect_to login_path, notice: "Ha létezik aktív fiók ezzel az e-mail címmel, elküldtük a jelszó-visszaállító linket."
  end

  def edit
  end

  def update
    new_password = params.dig(:user, :password).to_s
    if new_password.blank?
      @user.errors.add(:password, "megadása kötelező")
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password_reset_params.merge(must_change_password: false))
      redirect_to login_path, notice: "A jelszavad sikeresen megváltozott. Jelentkezz be az új jelszóval!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def ensure_email_system_enabled
    return if Setting.email_system?

    redirect_to new_password_reset_path, alert: "Az e-mailes jelszó-visszaállítás jelenleg ki van kapcsolva. Kérj ideiglenes jelszót az Admintól."
  end

  def load_user_by_token
    @token = params[:token].to_s
    @user = User.find_by_token_for(:password_reset, @token)
    return if @user.present?

    redirect_to new_password_reset_path, alert: "A jelszó-visszaállító link érvénytelen vagy lejárt."
  end

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
