require "test_helper"

class LeaderboardCalculatorTest < ActiveSupport::TestCase
  test "computes logarithmic placement points accurately" do
    assert_equal 0, LeaderboardCalculator.points_for(0, 1)
    assert_equal 0, LeaderboardCalculator.points_for(5, 0)
    assert_equal 0, LeaderboardCalculator.points_for(5, 6)

    assert_equal [ 1 ], (1..1).map { |k| LeaderboardCalculator.points_for(1, k) }
    assert_equal [ 2, 1 ], (1..2).map { |k| LeaderboardCalculator.points_for(2, k) }
    assert_equal [ 3, 2, 1 ], (1..3).map { |k| LeaderboardCalculator.points_for(3, k) }
    assert_equal [ 5, 3, 2, 1, 1 ], (1..5).map { |k| LeaderboardCalculator.points_for(5, k) }
    assert_equal [ 8, 5, 4, 3, 2, 2, 1, 1 ], (1..8).map { |k| LeaderboardCalculator.points_for(8, k) }
    assert_equal [ 12, 8, 6, 5, 4, 3, 3, 2, 2, 1, 1, 1 ], (1..12).map { |k| LeaderboardCalculator.points_for(12, k) }
  end

  test "counts only personal best per user, breaks ties by created_at, and ignores inactive users" do
    u1 = create_user("peti", "Kovács Peti", created_at: 5.days.ago)
    u2 = create_user("bence", "Nagy Bence", created_at: 4.days.ago)
    u3 = create_user("adam", "Tóth Ádám", created_at: 3.days.ago)
    u_inactive = create_user("banned", "Tiltott Tag", is_active: false, created_at: 2.days.ago)

    cat = Category.create!(name: "100m sörfutás", unit: "mp", value_type: "TIME_DURATION", sort_direction: "ASC")

    r_u1 = Record.create!(user: u1, category: cat, value: "18.42", achieved_at: Date.current, status: "APPROVED", created_at: 3.days.ago)
    r_u2_best = Record.create!(user: u2, category: cat, value: "19.50", achieved_at: Date.current, status: "APPROVED", created_at: 2.days.ago)
    r_u2_worse = Record.create!(user: u2, category: cat, value: "21.00", achieved_at: Date.current, status: "APPROVED", created_at: 4.days.ago)
    r_u3_tie = Record.create!(user: u3, category: cat, value: "19.50", achieved_at: Date.current, status: "APPROVED", created_at: 1.day.ago)
    Record.create!(user: u3, category: cat, value: "10.00", achieved_at: Date.current, status: "PENDING")
    Record.create!(user: u_inactive, category: cat, value: "15.00", achieved_at: Date.current, status: "APPROVED")

    standings = LeaderboardCalculator.category_standings(cat)
    assert_equal 3, standings.participants_count
    assert_equal 3, standings.max_points
    assert_equal r_u1.id, standings.top_entry.record.id

    assert_equal [ r_u1.id, r_u2_best.id, r_u3_tie.id, r_u2_worse.id ], standings.entries.map { |e| e.record.id }

    first, second, third, secondary = standings.entries
    assert_equal [ 1, 3, true, false ], [ first.rank, first.points, first.personal_best?, first.tied_sort_value ]
    assert_equal [ 2, 2, true, true, true ], [ second.rank, second.points, second.personal_best?, second.tied_sort_value, second.tied_earlier ]
    assert_equal [ 3, 1, true, true, true ], [ third.rank, third.points, third.personal_best?, third.tied_sort_value, third.tied_later? ]
    assert_nil secondary.rank
    assert_equal 0, secondary.points
    assert_not secondary.personal_best?
  end

  test "computes overall and seasonal leaderboards, tie-breakers, and excludes archived categories" do
    u1 = create_user("alpha", "Első Anna", created_at: 10.days.ago)
    u2 = create_user("beta", "Második Béla", created_at: 5.days.ago)
    u3 = create_user("gamma", "Harmadik Gábor", created_at: 2.days.ago)

    season = Season.create!(name: "2026 Őszi Szezon", starts_at: 20.days.ago, ends_at: 10.days.from_now)

    # Active category outside season (2 participants: 1st = 2 pt, 2nd = 1 pt)
    old_cat = Category.create!(name: "Régi szám", unit: "kg", value_type: "DOUBLE", sort_direction: "DESC", created_at: 40.days.ago)
    Record.create!(user: u2, category: old_cat, value: "100", achieved_at: Date.current, status: "APPROVED")
    Record.create!(user: u1, category: old_cat, value: "90", achieved_at: Date.current, status: "APPROVED")

    # Active category inside season (2 participants: 1st = 2 pt, 2nd = 1 pt)
    season_cat = Category.create!(name: "Szezon szám", unit: "db", value_type: "INT", sort_direction: "DESC", created_at: 5.days.ago)
    Record.create!(user: u1, category: season_cat, value: "25", achieved_at: Date.current, status: "APPROVED")
    Record.create!(user: u2, category: season_cat, value: "20", achieved_at: Date.current, status: "APPROVED")

    # Archived category (must not award points in overall or seasonal)
    archived_cat = Category.create!(name: "Archivált szám", unit: "db", value_type: "INT", sort_direction: "DESC", created_at: 2.days.ago)
    Record.create!(user: u3, category: archived_cat, value: "99", achieved_at: Date.current, status: "APPROVED")
    archived_cat.update!(is_archived: true)

    archived_standings = LeaderboardCalculator.category_standings(archived_cat)
    assert_equal 0, archived_standings.max_points
    assert_equal 0, archived_standings.top_entry.points

    # Both u1 and u2 have 3 total_points, 1 first place, 2 categories -> tie-break by users.created_at ASC (u1 wins!)
    overall = LeaderboardCalculator.overall_leaderboard
    assert_equal [ u1.id, u2.id ], overall.entries.map(&:user_id)
    assert_equal [ 3, 3 ], overall.entries.map(&:total_points)
    assert_equal [ 1, 2 ], overall.entries.map(&:rank)
    assert_equal 0, overall.points_for_user(u3)
    assert_nil overall.entry_for(u3).rank

    seasonal = LeaderboardCalculator.seasonal_leaderboard(season)
    assert_equal [ u1.id, u2.id ], seasonal.entries.map(&:user_id)
    assert_equal [ 2, 1 ], seasonal.entries.map(&:total_points)
  end

  test "uses first_places_count and categories_count as overall tie-breakers and invalidates cache on changes" do
    u1 = create_user("first_place_king", "Első Király", created_at: 1.day.ago)
    u2 = create_user("consistent_runner", "Második Márk", created_at: 10.days.ago)

    # Category 1 (1 participant): u1 gets 1 pt (1st place)
    c1 = Category.create!(name: "Egyedüli szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    Record.create!(user: u1, category: c1, value: "10", achieved_at: Date.current, status: "APPROVED")

    # Category 2 (2 participants): u1 gets 2 pt (1st place), u2 gets 1 pt (2nd place) -> total u1=3, u2=1
    c2 = Category.create!(name: "Kettős szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    Record.create!(user: u1, category: c2, value: "20", achieved_at: Date.current, status: "APPROVED")
    Record.create!(user: u2, category: c2, value: "15", achieved_at: Date.current, status: "APPROVED")

    # Category 3 (3 participants): u2 gets 2nd place (2 pt) -> total u2=3, u1=3; u1 has 2 first places vs u2's 0!
    u3 = create_user("third", "Harmadik Huba", created_at: 15.days.ago)
    c3 = Category.create!(name: "Hármas szám", unit: "db", value_type: "INT", sort_direction: "DESC")
    Record.create!(user: u3, category: c3, value: "30", achieved_at: Date.current, status: "APPROVED")
    Record.create!(user: u2, category: c3, value: "20", achieved_at: Date.current, status: "APPROVED")
    # Make u1 not participate in c3 so u1 has 3 pt from c1+c2 (2 first places)
    # Wait: with 2 participants in c3, 2nd place = 1 pt. Let's add u4 to c3 so 2nd place = 2 pt (N=3).
    u4 = create_user("fourth", "Negyedik Nóra", created_at: 20.days.ago)
    Record.create!(user: u4, category: c3, value: "10", achieved_at: Date.current, status: "APPROVED")

    overall = LeaderboardCalculator.overall_leaderboard
    u1_entry = overall.entry_for(u1)
    u2_entry = overall.entry_for(u2)
    assert_equal 3, u1_entry.total_points
    assert_equal 3, u2_entry.total_points
    assert_equal 2, u1_entry.first_places_count
    assert_equal 0, u2_entry.first_places_count
    assert u1_entry.rank < u2_entry.rank

    # Verify cache invalidation with MemoryStore
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      v1 = LeaderboardCalculator.cache_version
      assert_equal v1, LeaderboardCalculator.cache_version
      assert_equal 3, LeaderboardCalculator.overall_leaderboard.points_for_user(u1)

      c1.update!(is_archived: true)
      v2 = LeaderboardCalculator.cache_version
      assert_not_equal v1, v2
      assert_equal 2, LeaderboardCalculator.overall_leaderboard.points_for_user(u1)
    ensure
      Rails.cache = original_cache
    end
  end

  private

  def create_user(username, display_name, is_active: true, created_at: Time.current)
    User.create!(
      username: username,
      display_name: display_name,
      password: "password123",
      password_confirmation: "password123",
      is_active: is_active,
      confirmed_at: Time.current,
      created_at: created_at
    )
  end
end
