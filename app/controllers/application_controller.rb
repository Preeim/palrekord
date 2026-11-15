class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :enforce_password_change

  helper_method :current_user, :logged_in?, :admin?, :can_create_category?, :current_user_total_points

  private

  def set_current_user
    return unless session[:user_id]

    user = User.find_by(id: session[:user_id])
    if user&.is_active?
      Current.user = user
    else
      reset_session
      Current.user = nil
      flash[:alert] = "A fiókod fel van függesztve vagy nem elérhető." if user && !user.is_active?
    end
  end

  def enforce_password_change
    return unless Current.user&.must_change_password?
    return if controller_name == "help"
    return if controller_name == "profiles" && action_name.in?(%w[show update_password])
    return if controller_name == "sessions" && action_name == "destroy"

    redirect_to profile_path, alert: "Ideiglenes jelszóval léptél be. A folytatáshoz kötelező megváltoztatni a jelszavadat."
  end

  def current_user
    Current.user
  end

  def logged_in?
    Current.user.present?
  end

  def admin?
    Current.user&.admin? || false
  end

  def can_create_category?
    logged_in? && (admin? || Setting.members_can_create_categories?)
  end

  def current_user_total_points
    return 0 unless logged_in?

    @current_user_total_points ||= LeaderboardCalculator.overall_leaderboard.points_for_user(current_user)
  end

  def require_authentication
    return if logged_in?

    redirect_to login_path, alert: "A folytatáshoz be kell jelentkezned."
  end

  def require_guest
    return unless logged_in?

    redirect_to root_path, notice: "Már be vagy jelentkezve."
  end

  def require_admin
    return require_authentication unless logged_in?
    return if admin?

    redirect_to root_path, alert: "Nincs jogosultságod ehhez a művelethez."
  end

  def require_leaderboard_access
    return if logged_in? || Setting.public_leaderboards?

    redirect_to login_path, alert: "A ranglisták megtekintéséhez be kell jelentkezned."
  end
end
