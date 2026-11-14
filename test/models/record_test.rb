require "test_helper"

class RecordTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      username: "tester1",
      display_name: "Teszt Elek",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end

  test "computes sort_value for INT, DOUBLE, TIME_DURATION, and DATE categories" do
    int_cat = Category.create!(name: "Palacsinta", unit: "db", value_type: "INT", sort_direction: "DESC")
    double_cat = Category.create!(name: "Fekvenyomás", unit: "kg", value_type: "DOUBLE", sort_direction: "DESC")
    time_cat = Category.create!(name: "Sörfutás", unit: "mp", value_type: "TIME_DURATION", sort_direction: "ASC")
    date_cat = Category.create!(name: "Első maraton", unit: "-", value_type: "DATE", sort_direction: "ASC")

    r1 = Record.create!(user: @user, category: int_cat, value: "19", achieved_at: Date.new(2026, 1, 1))
    assert_equal BigDecimal("19"), r1.sort_value

    r2 = Record.create!(user: @user, category: double_cat, value: "125,5", achieved_at: Date.new(2026, 1, 1))
    assert_equal "125.5", r2.value
    assert_equal BigDecimal("125.5"), r2.sort_value

    r3 = Record.create!(user: @user, category: time_cat, value: "04:12.50", achieved_at: Date.new(2026, 1, 1))
    assert_equal BigDecimal("252.5"), r3.sort_value

    r4 = Record.create!(user: @user, category: time_cat, value: "01:02:03.25", achieved_at: Date.new(2026, 1, 1))
    assert_equal BigDecimal("3723.25"), r4.sort_value

    r5 = Record.create!(user: @user, category: date_cat, value: "2026-11-13", achieved_at: Date.new(2026, 11, 13))
    assert_equal BigDecimal(Date.new(2026, 11, 13).jd), r5.sort_value
  end

  test "rejects invalid values and archived categories" do
    time_cat = Category.create!(name: "Plank", unit: "mp", value_type: "TIME_DURATION", sort_direction: "DESC")
    invalid = Record.new(user: @user, category: time_cat, value: "01:75", achieved_at: Date.current)
    assert_not invalid.valid?

    archived_cat = Category.create!(name: "Régi szám", unit: "db", value_type: "INT", sort_direction: "DESC", is_archived: true)
    archived_rec = Record.new(user: @user, category: archived_cat, value: "10", achieved_at: Date.current)
    assert_not archived_rec.valid?
    assert archived_rec.errors[:category].present?
  end

  test "orders approved records by sort_direction, breaks ties by earlier created_at, and excludes inactive users" do
    cat = Category.create!(name: "Sprint", unit: "mp", value_type: "TIME_DURATION", sort_direction: "ASC")
    second_user = User.create!(
      username: "tester2",
      display_name: "Másik Béla",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    inactive_user = User.create!(
      username: "inactive1",
      display_name: "Inaktív Imre",
      password: "password123",
      password_confirmation: "password123",
      is_active: false,
      confirmed_at: Time.current
    )

    earlier_upload = Record.create!(
      user: @user,
      category: cat,
      value: "18.42",
      achieved_at: Date.new(2026, 5, 20),
      status: "APPROVED",
      created_at: 2.days.ago
    )
    later_upload = Record.create!(
      user: second_user,
      category: cat,
      value: "18.42",
      achieved_at: Date.new(2026, 5, 10),
      status: "APPROVED",
      created_at: 1.day.ago
    )
    Record.create!(user: @user, category: cat, value: "15.00", achieved_at: Date.new(2026, 5, 1), status: "PENDING")
    Record.create!(user: inactive_user, category: cat, value: "12.00", achieved_at: Date.new(2026, 5, 1), status: "APPROVED")

    ordered = cat.approved_records_ordered.to_a
    assert_equal [ earlier_upload.id, later_upload.id ], ordered.map(&:id)
    assert_equal earlier_upload.id, cat.top_record.id
  end

  test "rejects decimals for INT and impossible calendar dates for DATE, and orders DESC categories highest-first" do
    int_cat = Category.create!(name: "Fekvőtámasz", unit: "db", value_type: "INT", sort_direction: "DESC")
    bad_int = Record.new(user: @user, category: int_cat, value: "12.5", achieved_at: Date.current)
    assert_not bad_int.valid?
    assert bad_int.errors[:value].present?

    date_cat = Category.create!(name: "Mérföldkő", unit: "-", value_type: "DATE", sort_direction: "DESC")
    bad_date = Record.new(user: @user, category: date_cat, value: "2026-02-30", achieved_at: Date.current)
    assert_not bad_date.valid?
    assert bad_date.errors[:value].present?

    second_user = User.create!(
      username: "desc_tester",
      display_name: "Csökkenő Csaba",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    low = Record.create!(user: @user, category: int_cat, value: "30", achieved_at: Date.current, status: "APPROVED")
    high = Record.create!(user: second_user, category: int_cat, value: "55", achieved_at: Date.current, status: "APPROVED")

    assert_equal [ high.id, low.id ], int_cat.approved_records_ordered.pluck(:id)
    assert_equal high.id, int_cat.top_record.id
  end
end
