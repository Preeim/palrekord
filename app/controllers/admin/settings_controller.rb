module Admin
  class SettingsController < BaseController
    def index
      Setting.ensure_defaults!
      @settings = Setting.order(:id)
    end

    def update
      @setting = Setting.find(params[:id])
      new_value = ActiveModel::Type::Boolean.new.cast(params.dig(:setting, :value)) ? "true" : "false"
      @setting.update!(value: new_value)
      redirect_to admin_settings_path, notice: "Beállítás (#{@setting.key}) frissítve: #{new_value}."
    end
  end
end
