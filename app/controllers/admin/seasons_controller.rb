module Admin
  class SeasonsController < BaseController
    before_action :set_season, only: [ :edit, :update, :destroy ]

    def index
      @seasons = Season.includes(:created_by).ordered
      @season = Season.new(
        starts_at: Time.current.beginning_of_month,
        ends_at: 2.months.from_now.end_of_month
      )
    end

    def create
      @season = Season.new(season_params)
      @season.created_by = current_user

      if @season.save
        redirect_to admin_seasons_path, notice: "Szezon létrehozva: #{@season.name}"
      else
        @seasons = Season.includes(:created_by).ordered
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @season.update(season_params)
        redirect_to admin_seasons_path, notice: "Szezon frissítve: #{@season.name}"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      name = @season.name
      @season.destroy
      redirect_to admin_seasons_path, notice: "Szezon (#{name}) törölve."
    end

    private

    def set_season
      @season = Season.find(params[:id])
    end

    def season_params
      params.require(:season).permit(:name, :starts_at, :ends_at)
    end
  end
end
