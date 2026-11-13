class RecordsController < ApplicationController
  before_action :require_authentication
  before_action :set_record, only: [ :edit, :update, :destroy ]
  before_action :authorize_record_modification!, only: [ :edit, :update, :destroy ]
  before_action :load_categories, only: [ :new, :create, :edit, :update ]

  def new
    @record = current_user.records.build(
      category_id: params[:category_id],
      achieved_at: Date.current
    )
    @record.attachments.build
  end

  def create
    @record = current_user.records.build(record_params)
    @record.status = Setting.require_record_approval? ? "PENDING" : "APPROVED"
    @record.reviewed_at = Time.current if @record.approved?

    if @record.save
      if @record.approved?
        redirect_to @record.category, notice: "Rekord sikeresen rögzítve a ranglistára!"
      else
        redirect_to profile_path, notice: "Rekord beküldve, adminisztrátori jóváhagyásra vár."
      end
    else
      @record.attachments.build if @record.attachments.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @record.attachments.build if @record.attachments.empty?
  end

  def update
    if @record.update(record_params)
      redirect_to profile_path, notice: "Rekord sikeresen frissítve."
    else
      @record.attachments.build if @record.attachments.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record.destroy
    redirect_to profile_path, notice: "Rekord sikeresen törölve."
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def authorize_record_modification!
    return if admin?
    return if @record.user_id == current_user.id && @record.pending?

    redirect_to profile_path, alert: "Csak a függőben lévő (PENDING) saját rekordodat szerkesztheted vagy törölheted."
  end

  def load_categories
    @categories = Category.active.ordered
    if @record&.category&.is_archived?
      @categories = Category.where(id: @categories.pluck(:id) + [ @record.category_id ]).ordered
    end
  end

  def record_params
    params.require(:record).permit(
      :category_id,
      :value,
      :achieved_at,
      :note,
      attachments_attributes: [ :id, :file_type, :uploaded_file, :file_path_or_url, :text_content, :_destroy ]
    )
  end
end
