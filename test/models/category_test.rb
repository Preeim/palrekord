require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "normalizes name and unit and enforces case-insensitive uniqueness" do
    cat = Category.create!(
      name: "  Fekvenyomás max  ",
      unit: "  kg ",
      value_type: "DOUBLE",
      sort_direction: "DESC"
    )
    assert_equal "Fekvenyomás max", cat.name
    assert_equal "kg", cat.unit
    assert_equal "DOUBLE · DESC", cat.sort_by_label

    duplicate = Category.new(name: "fekvenyomás max", unit: "kg", value_type: "DOUBLE", sort_direction: "DESC")
    assert_not duplicate.valid?
    assert duplicate.errors[:name].present?
  end

  test "rejects invalid value_type and sort_direction" do
    invalid = Category.new(name: "Teszt", unit: "db", value_type: "FLOAT", sort_direction: "UP")
    assert_not invalid.valid?
    assert invalid.errors[:value_type].present?
    assert invalid.errors[:sort_direction].present?
  end

  test "formats display_record_value properly across types and units" do
    user = User.create!(
      username: "cattester",
      display_name: "Kategória Tesztelő",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    time_colon_cat = Category.create!(name: "Plank", unit: "mp", value_type: "TIME_DURATION", sort_direction: "DESC")
    r1 = Record.create!(user: user, category: time_colon_cat, value: "04:12.00", achieved_at: Date.current)
    assert_equal "04:12.00", time_colon_cat.display_record_value(r1)

    time_sec_cat = Category.create!(name: "Sprint", unit: "mp", value_type: "TIME_DURATION", sort_direction: "ASC")
    r2 = Record.create!(user: user, category: time_sec_cat, value: "18.42", achieved_at: Date.current)
    assert_equal "18.42 mp", time_sec_cat.display_record_value(r2)

    date_cat = Category.create!(name: "Első teljesítés", unit: "-", value_type: "DATE", sort_direction: "ASC")
    r3 = Record.create!(user: user, category: date_cat, value: "2026-11-13", achieved_at: Date.current)
    assert_equal "2026-11-13", date_cat.display_record_value(r3)

    assert_equal "", date_cat.display_record_value(nil)
  end

  test "destroys associated records when category is destroyed" do
    user = User.create!(
      username: "catdestroy",
      display_name: "Törlés Teszt",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    cat = Category.create!(name: "Ideiglenes szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    Record.create!(user: user, category: cat, value: "10", achieved_at: Date.current)

    assert_difference("Record.count", -1) do
      cat.destroy!
    end
  end

  test "normalizes and validates verification fields on category" do
    cat = Category.create!(
      name: "Kocka teszt",
      unit: "mp",
      value_type: "DOUBLE",
      sort_direction: "ASC",
      recommended_file_type: "  image  ",
      verification_hint: "  Közös fotó a kockáról és timerről  "
    )
    assert_equal "IMAGE", cat.recommended_file_type
    assert_equal "Közös fotó a kockáról és timerről", cat.verification_hint
    assert_equal "📷 Fotó / Képernyőkép", cat.recommended_file_type_label

    invalid = Category.new(
      name: "Rossz típus",
      unit: "db",
      value_type: "INT",
      sort_direction: "DESC",
      recommended_file_type: "VIDEO"
    )
    assert_not invalid.valid?
    assert invalid.errors[:recommended_file_type].present?
  end
end
