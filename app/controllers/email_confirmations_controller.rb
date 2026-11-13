class EmailConfirmationsController < ApplicationController
  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    if user.present?
      user.update!(confirmed_at: Time.current) unless user.confirmed?
      redirect_to login_path, notice: "Az e-mail címed megerősítése sikeres! Most már bejelentkezhetsz."
    else
      redirect_to login_path, alert: "A megerősítő link érvénytelen vagy lejárt."
    end
  end
end
