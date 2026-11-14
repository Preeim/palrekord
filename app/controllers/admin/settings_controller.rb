module Admin
  class SettingsController < BaseController
    def index
      Setting.ensure_defaults!
      @settings = Setting.order(:id)
    end

    def update
      @setting = Setting.find(params[:id])
      raw_value = params.dig(:setting, :value).to_s.strip

      if @setting.integer_setting?
        parsed = Integer(raw_value, exception: false)
        if parsed.nil? || parsed.negative?
          redirect_to admin_settings_path, alert: "A(z) #{@setting.key} értékének nemnegatív egész számnak kell lennie."
          return
        end
        new_value = parsed.to_s
      else
        new_value = ActiveModel::Type::Boolean.new.cast(raw_value) ? "true" : "false"
      end

      @setting.update!(value: new_value)
      redirect_to admin_settings_path, notice: "Beállítás (#{@setting.key}) frissítve: #{new_value}."
    end
  end
end
