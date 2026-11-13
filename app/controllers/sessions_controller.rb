class SessionsController < ApplicationController
  before_action :require_guest, only: [ :new, :create ]

  def new
  end

  def create
    user = User.authenticate_by_login(params[:login], params[:password])

    if user.nil?
      flash.now[:alert] = "Hibás felhasználónév/e-mail vagy jelszó."
      render :new, status: :unprocessable_entity
      return
    end

    unless user.is_active?
      flash.now[:alert] = "A fiókod fel van függesztve."
      render :new, status: :unprocessable_entity
      return
    end

    if Setting.email_system? && !user.confirmed?
      flash.now[:alert] = "Kérjük, erősítsd meg az e-mail címed a belépés előtt."
      render :new, status: :unprocessable_entity
      return
    end

    reset_session
    session[:user_id] = user.id
    user.update_column(:last_login_at, Time.current)

    if user.must_change_password?
      redirect_to profile_path, alert: "Ideiglenes jelszóval léptél be. Kérjük, változtasd meg a jelszavadat!"
    else
      redirect_to root_path, notice: "Sikeres bejelentkezés!"
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Sikeresen kijelentkeztél."
  end
end
