class AttachmentsController < ApplicationController
  before_action :set_attachment
  before_action :authorize_attachment_access!

  def show
    pathname = @attachment.stored_file_pathname
    if pathname
      send_file pathname,
        filename: @attachment.original_filename.presence || pathname.basename.to_s,
        disposition: :inline
    else
      head :not_found
    end
  end

  private

  def set_attachment
    @attachment = Attachment.includes(:record).find(params[:id])
  end

  def authorize_attachment_access!
    if @attachment.record.approved?
      require_leaderboard_access
    elsif logged_in? && (admin? || @attachment.record.user_id == current_user.id)
      true
    else
      redirect_to login_path, alert: "Nincs jogosultságod a melléklet megtekintéséhez."
    end
  end
end
