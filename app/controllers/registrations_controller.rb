class RegistrationsController < ApplicationController
  before_action :require_guest

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = User.admins.none? ? "ADMIN" : "TAG"
    @user.confirmed_at = Setting.email_system? ? nil : Time.current

    invite_required = Setting.require_invite_code?
    invite_code_input = params[:invite_code].to_s.strip.upcase

    if invite_required && invite_code_input.blank?
      @user.valid?
      @user.errors.add(:base, "A meghívókód megadása kötelező.")
      render :new, status: :unprocessable_entity
      return
    end

    saved = false

    ActiveRecord::Base.transaction do
      if invite_required
        invite_code = InviteCode.lock.find_by(code: invite_code_input)
        unless invite_code&.usable?
          @user.valid?
          @user.errors.add(:base, "Érvénytelen, lejárt vagy felhasznált meghívókód.")
          raise ActiveRecord::Rollback
        end

        @user.invite_code = invite_code
        unless @user.save
          raise ActiveRecord::Rollback
        end

        invite_code.increment!(:uses_count)
        saved = true
      else
        if @user.save
          saved = true
        else
          raise ActiveRecord::Rollback
        end
      end
    end

    unless saved
      render :new, status: :unprocessable_entity
      return
    end

    if Setting.email_system?
      UserMailer.email_confirmation(@user).deliver_later
      redirect_to login_path, notice: "Sikeres regisztráció! Küldtünk egy megerősítő levelet az e-mail címedre."
    else
      reset_session
      session[:user_id] = @user.id
      @user.update_column(:last_login_at, Time.current)
      redirect_to root_path, notice: "Sikeres regisztráció! Üdvözlünk a PálRecordon."
    end
  end

  private

  def registration_params
    params.require(:user).permit(:username, :display_name, :email, :password, :password_confirmation)
  end
end
