class CategoriesController < ApplicationController
  before_action :require_leaderboard_access, only: [ :index, :show ]
  before_action :require_category_creation_permission, only: [ :new, :create ]
  before_action :require_admin, only: [ :edit, :update ]
  before_action :set_category, only: [ :show, :edit, :update ]

  def index
    @categories = Category.ordered
  end

  def show
    @records = @category.approved_records_ordered
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.created_by = current_user

    if @category.save
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
    params.require(:category).permit(:name, :description, :unit, :value_type, :sort_direction)
  end

  def admin_category_params
    params.require(:category).permit(:name, :description, :unit, :value_type, :sort_direction, :is_archived)
  end
end
