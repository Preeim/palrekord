require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "ensure_defaults! creates all expected settings with defaults" do
    Setting.delete_all
    Setting.ensure_defaults!

    assert_equal Setting::DEFAULTS.keys.sort, Setting.pluck(:key).sort
    assert_not Setting.email_system?
    assert Setting.require_invite_code?
    assert Setting.public_leaderboards?
    assert_not Setting.members_can_create_categories?
    assert Setting.require_record_approval?
    assert_equal 2, Setting.monthly_category_limit
  end

  test "get, set, and get_bool update and read settings" do
    Setting.ensure_defaults!

    Setting.set("email_system", "true")
    assert_equal "true", Setting.get(:email_system)
    assert Setting.get_bool("email_system")
    assert Setting.email_system?

    Setting.set("public_leaderboards", false)
    assert_not Setting.public_leaderboards?
    assert_not Setting.find_by!(key: "public_leaderboards").boolean_value?
  end

  test "monthly_category_limit handles valid integers and falls back to 2 on invalid values" do
    Setting.set("monthly_category_limit", "5")
    assert_equal 5, Setting.monthly_category_limit
    assert Setting.find_by!(key: "monthly_category_limit").integer_setting?

    Setting.set("monthly_category_limit", "0")
    assert_equal 0, Setting.monthly_category_limit

    Setting.set("monthly_category_limit", "-3")
    assert_equal 2, Setting.monthly_category_limit

    Setting.set("monthly_category_limit", "abc")
    assert_equal 2, Setting.monthly_category_limit
  end
end
