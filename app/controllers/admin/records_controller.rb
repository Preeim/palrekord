module Admin
  class RecordsController < BaseController
    before_action :set_record, only: [ :update, :destroy ]

    def index
      @status_filter = params[:status].presence_in(%w[PENDING APPROVED REJECTED ALL]) || "PENDING"
      scope = Record.includes(:user, :category, :attachments, :reviewed_by).newest_first
      @records = @status_filter == "ALL" ? scope : scope.where(status: @status_filter)

      @pending_count = Record.pending.count
      @approved_count = Record.approved.count
      @rejected_count = Record.rejected.count
    end

    def update
      new_status = params.dig(:record, :status)
      unless Record::STATUSES.include?(new_status)
        redirect_to admin_records_path, alert: "Érvénytelen státusz."
        return
      end

      @record.update!(
        status: new_status,
        admin_comment: params.dig(:record, :admin_comment).presence,
        reviewed_by: current_user,
        reviewed_at: Time.current
      )

      label = new_status == "APPROVED" ? "jóváhagyva" : "elutasítva"
      redirect_to admin_records_path(status: params[:return_status].presence || "PENDING"),
        notice: "Rekord (#{@record.user.display_name} – #{@record.value}) #{label}."
    end

    def destroy
      @record.destroy
      redirect_to admin_records_path(status: params[:return_status].presence || "PENDING"),
        notice: "Rekord véglegesen törölve."
    end

    private

    def set_record
      @record = Record.find(params[:id])
    end
  end
end
