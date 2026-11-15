class HelpController < ApplicationController
  def show
    @monthly_category_limit = Setting.monthly_category_limit
    @require_invite_code = Setting.require_invite_code?
    @require_record_approval = Setting.require_record_approval?
    @email_system = Setting.email_system?
    @members_can_create_categories = Setting.members_can_create_categories?
  end
end
