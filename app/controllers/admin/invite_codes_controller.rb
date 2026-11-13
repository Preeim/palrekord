module Admin
  class InviteCodesController < BaseController
    before_action :set_invite_code, only: [ :update, :destroy ]

    def index
      @invite_codes = InviteCode.includes(:created_by).newest_first
      @invite_code = InviteCode.new
    end

    def create
      @invite_code = InviteCode.new(invite_code_params)
      @invite_code.created_by = current_user

      if @invite_code.save
        redirect_to admin_invite_codes_path, notice: "Meghívókód létrehozva: #{@invite_code.code}"
      else
        @invite_codes = InviteCode.includes(:created_by).newest_first
        render :index, status: :unprocessable_entity
      end
    end

    def update
      if @invite_code.update(update_params)
        redirect_to admin_invite_codes_path, notice: "Meghívókód (#{@invite_code.code}) állapota frissítve."
      else
        redirect_to admin_invite_codes_path, alert: @invite_code.errors.full_messages.to_sentence
      end
    end

    def destroy
      code = @invite_code.code
      @invite_code.destroy
      redirect_to admin_invite_codes_path, notice: "Meghívókód (#{code}) törölve."
    end

    private

    def set_invite_code
      @invite_code = InviteCode.find(params[:id])
    end

    def invite_code_params
      params.require(:invite_code).permit(:code, :label, :max_uses, :expires_at)
    end

    def update_params
      params.require(:invite_code).permit(:is_active)
    end
  end
end
