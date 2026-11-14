require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "validates name, dates, and ends_at after starts_at" do
    season = Season.new(
      name: "  2026 Őszi Szezon  ",
      starts_at: Time.zone.local(2026, 9, 1, 0, 0, 0),
      ends_at: Time.zone.local(2026, 11, 30, 23, 59, 59)
    )
    assert season.valid?
    assert_equal "2026 Őszi Szezon", season.name
    season.save!

    duplicate = Season.new(
      name: "2026 őszi szezon",
      starts_at: Time.zone.local(2026, 10, 1, 0, 0, 0),
      ends_at: Time.zone.local(2026, 12, 1, 0, 0, 0)
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:name].present?

    invalid_range = Season.new(
      name: "Hibás szezon",
      starts_at: Time.zone.local(2026, 10, 10, 12, 0, 0),
      ends_at: Time.zone.local(2026, 10, 10, 12, 0, 0)
    )
    assert_not invalid_range.valid?
    assert invalid_range.errors[:ends_at].present?
  end

  test "determines active status and matches active categories created within range" do
    now = Time.current
    past = Season.create!(name: "Múlt szezon", starts_at: 3.months.ago, ends_at: 2.months.ago)
    active = Season.create!(name: "Aktív szezon", starts_at: 10.days.ago, ends_at: 10.days.from_now)
    future = Season.create!(name: "Jövő szezon", starts_at: 1.month.from_now, ends_at: 2.months.from_now)

    assert_equal "Lezárt", past.status_label(now)
    assert_equal "Aktív", active.status_label(now)
    assert_equal "Közelgő", future.status_label(now)
    assert_equal active, Season.current(now)

    inside_cat = Category.create!(name: "Szezon kategória", unit: "db", value_type: "INT", sort_direction: "DESC", created_at: 2.days.ago)
    archived_inside_cat = Category.create!(name: "Archivált szezon kat", unit: "db", value_type: "INT", sort_direction: "DESC", is_archived: true, created_at: 1.day.ago)
    outside_cat = Category.create!(name: "Régi kategória", unit: "db", value_type: "INT", sort_direction: "DESC", created_at: 6.months.ago)

    assert_includes active.categories, inside_cat
    assert_includes active.categories, archived_inside_cat
    assert_not_includes active.categories, outside_cat

    assert_equal [ inside_cat ], active.active_categories.to_a
    assert_equal active, inside_cat.matching_season
    assert_nil outside_cat.matching_season
  end
end
