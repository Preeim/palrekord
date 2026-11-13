module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :update, :destroy, :reset_password ]

    def index
      @users = User.order(created_at: :asc)
    end

    def update
      permitted = user_params

      if permitted.key?(:role) && permitted[:role] == "TAG" && @user.last_active_admin?
        redirect_to admin_users_path, alert: "Az utolsó aktív adminisztrátor nem fokozható le."
        return
      end

      if permitted.key?(:is_active) && ActiveModel::Type::Boolean.new.cast(permitted[:is_active]) == false
        if @user == current_user
          redirect_to admin_users_path, alert: "Saját fiókodat nem függesztheted fel."
          return
        elsif @user.last_active_admin?
          redirect_to admin_users_path, alert: "Az utolsó aktív adminisztrátor nem függeszthető fel."
          return
        end
      end

      if @user.update(permitted)
        redirect_to admin_users_path, notice: "Felhasználó (#{@user.username}) adatai frissítve."
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Saját fiókodat nem törölheted."
        return
      end

      if @user.last_active_admin?
        redirect_to admin_users_path, alert: "Az utolsó aktív adminisztrátor nem törölhető."
        return
      end

      username = @user.username
      @user.destroy
      redirect_to admin_users_path, notice: "Felhasználó (#{username}) törölve."
    end

    def reset_password
      temp_password = SecureRandom.alphanumeric(12)
      @user.update!(
        password: temp_password,
        password_confirmation: temp_password,
        must_change_password: true
      )

      flash[:temp_password_user] = @user.username
      flash[:temp_password_value] = temp_password
      redirect_to admin_users_path, notice: "Ideiglenes jelszó generálva (#{@user.username} részére)."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role, :is_active)
    end
  end
end
