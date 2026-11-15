module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [ :edit, :update, :destroy ]

    def index
      load_index_data
      @category = Category.new(value_type: "DOUBLE", sort_direction: "DESC")
    end

    def create
      @category = Category.new(category_params)
      @category.created_by = current_user

      if @category.save
        redirect_to admin_categories_path, notice: "Versenyszám létrehozva: #{@category.name}"
      else
        load_index_data
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path(status: return_status_param), notice: "Versenyszám frissítve: #{@category.name}"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      name = @category.name
      records_count = @category.records.count
      @category.destroy
      redirect_to admin_categories_path(status: return_status_param), notice: "Versenyszám (#{name}) és #{records_count} db rekordja törölve."
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def load_index_data
      @status_filter = %w[ALL ACTIVE ARCHIVED].include?(params[:status]) ? params[:status] : "ALL"
      @active_count = Category.active.count
      @archived_count = Category.archived.count
      @all_count = @active_count + @archived_count
      @seasons = Season.ordered.to_a

      scope = Category.includes(:created_by, :records).ordered
      @categories = case @status_filter
      when "ACTIVE"
        scope.active.to_a
      when "ARCHIVED"
        scope.archived.to_a
      else
        scope.to_a
      end
    end

    def return_status_param
      params[:return_status].presence
    end

    def category_params
      params.require(:category).permit(
        :name,
        :description,
        :unit,
        :value_type,
        :sort_direction,
        :recommended_file_type,
        :verification_hint,
        :is_archived
      )
    end
  end
end
