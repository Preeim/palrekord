class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :load_profile_data

  def show
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profiladatok sikeresen frissítve."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    unless @user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "A jelenlegi jelszó nem egyezik."
      render :show, status: :unprocessable_entity
      return
    end

    if params[:password].blank?
      @user.errors.add(:password, "nem lehet üres")
      render :show, status: :unprocessable_entity
      return
    end

    if @user.update(
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      must_change_password: false
    )
      redirect_to profile_path, notice: "Jelszavad sikeresen megváltozott."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_profile_data
    @user = current_user
    @records = current_user.records.includes(:category, :attachments, :reviewed_by).newest_first
  end

  def profile_params
    params.require(:user).permit(:display_name, :email)
  end
end
