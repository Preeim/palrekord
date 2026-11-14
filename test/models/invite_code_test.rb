require "test_helper"

class InviteCodeTest < ActiveSupport::TestCase
  test "generates code automatically when blank and normalizes provided code" do
    auto_code = InviteCode.create!
    assert_match(/\APAL-[A-Z0-9]{6}\z/, auto_code.code)

    custom = InviteCode.create!(code: "  pal-custom99  ", label: "  Baráti kör  ")
    assert_equal "PAL-CUSTOM99", custom.code
    assert_equal "Baráti kör", custom.label
  end

  test "evaluates expired?, exhausted?, usable?, and usage_summary" do
    active = InviteCode.create!(code: "PAL-OPEN01", max_uses: 3, uses_count: 1, expires_at: 2.days.from_now)
    assert active.usable?
    assert_not active.expired?
    assert_not active.exhausted?
    assert_equal "1 / 3", active.usage_summary

    unlimited = InviteCode.create!(code: "PAL-UNLIM1", max_uses: nil, uses_count: 5)
    assert unlimited.usable?
    assert_equal "5 / ∞", unlimited.usage_summary

    expired = InviteCode.create!(code: "PAL-EXP001", expires_at: 1.hour.ago)
    assert expired.expired?
    assert_not expired.usable?

    exhausted = InviteCode.create!(code: "PAL-EXH001", max_uses: 2, uses_count: 2)
    assert exhausted.exhausted?
    assert_not exhausted.usable?

    inactive = InviteCode.create!(code: "PAL-INACT1", is_active: false)
    assert_not inactive.usable?
  end

  test "nullifies user invite_code_id on destroy without deleting the user" do
    invite = InviteCode.create!(code: "PAL-NULL01")
    user = User.create!(
      username: "inviteduser",
      display_name: "Meghívott Tag",
      password: "password123",
      password_confirmation: "password123",
      invite_code: invite,
      confirmed_at: Time.current
    )

    assert_no_difference("User.count") do
      invite.destroy!
    end
    assert_nil user.reload.invite_code_id
  end
end
