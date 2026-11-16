class CategoriesController < ApplicationController
  before_action :require_leaderboard_access, only: [ :index, :show ]
  before_action :require_category_creation_permission, only: [ :new, :create ]
  before_action :require_admin, only: [ :edit, :update ]
  before_action :set_category, only: [ :show, :edit, :update ]

  def index
    @categories = Category.ordered.to_a
    @seasons = Season.ordered.to_a
    @current_season = Season.current
    @active_tab = params[:tab] == "season" ? "season" : "overall"
    @selected_season = if params[:season_id].present?
      @seasons.find { |s| s.id == params[:season_id].to_i } || @current_season || @seasons.first
    else
      @current_season || @seasons.first
    end
    @overall_leaderboard = LeaderboardCalculator.overall_leaderboard
    @seasonal_leaderboard = @selected_season ? LeaderboardCalculator.seasonal_leaderboard(@selected_season) : nil
    @category_standings = LeaderboardCalculator.standings_by_category(@categories)
  end

  def show
    @standings = LeaderboardCalculator.category_standings(@category)
    @records = @standings.entries.map(&:record)
    @category_season = @category.matching_season
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.created_by = current_user

    saved = current_user.with_lock { @category.save }
    if saved
      redirect_to @category, notice: "Versenyszám sikeresen létrehozva."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(admin_category_params)
      redirect_to @category, notice: "Versenyszám sikeresen frissítve."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def require_category_creation_permission
    return require_authentication unless logged_in?
    return if can_create_category?

    redirect_to root_path, alert: "Új versenyszám létrehozása csak adminisztrátor számára engedélyezett."
  end

  def category_params
    params.require(:category).permit(:name, :description, :unit, :value_type, :sort_direction, :recommended_file_type, :verification_hint)
  end

  def admin_category_params
    params.require(:category).permit(:name, :description, :unit, :value_type, :sort_direction, :recommended_file_type, :verification_hint, :is_archived)
  end
end
