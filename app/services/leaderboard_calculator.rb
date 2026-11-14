require "set"

class LeaderboardCalculator
  CACHE_VERSION_KEY = "leaderboard_calculator/version".freeze
  CACHE_TTL = 15.minutes

  CategoryStandingEntry = Struct.new(
    :record,
    :user,
    :user_id,
    :rank,
    :points,
    :personal_best,
    :tied_sort_value,
    :tied_earlier,
    keyword_init: true
  ) do
    def personal_best?
      personal_best
    end

    def tied_later?
      tied_sort_value && !tied_earlier
    end
  end

  CategoryStandings = Struct.new(
    :category_id,
    :participants_count,
    :max_points,
    :top_entry,
    :entries,
    :best_entries,
    keyword_init: true
  )

  BreakdownItem = Struct.new(
    :category_id,
    :category_name,
    :category_created_at,
    :rank,
    :participants_count,
    :points,
    :record_id,
    :record_value,
    :display_value,
    :achieved_at,
    keyword_init: true
  )

  LeaderboardEntry = Struct.new(
    :rank,
    :user_id,
    :username,
    :display_name,
    :user_created_at,
    :total_points,
    :first_places_count,
    :categories_count,
    :breakdown,
    keyword_init: true
  )

  class LeaderboardResult
    attr_reader :entries

    def initialize(entries:)
      @entries = entries
      @entries_by_user_id = entries.index_by(&:user_id)
    end

    def entry_for(user)
      return empty_entry(nil) unless user

      @entries_by_user_id[user.id] || empty_entry(user)
    end

    def points_for_user(user)
      entry_for(user).total_points
    end

    private

    def empty_entry(user)
      LeaderboardEntry.new(
        rank: nil,
        user_id: user&.id,
        username: user&.username,
        display_name: user&.display_name,
        user_created_at: user&.created_at,
        total_points: 0,
        first_places_count: 0,
        categories_count: 0,
        breakdown: []
      )
    end
  end

  def self.points_for(total_participants, rank)
    n = total_participants.to_i
    k = rank.to_i
    return 0 if n <= 0 || k <= 0 || k > n
    return 1 if n == 1 || k == n
    return n if k == 1

    ratio = [ 1.0 - (Math.log(k.to_f) / Math.log(n.to_f)), 0.0 ].max
    (1.0 + (n - 1) * (ratio ** 1.25)).round
  end

  def self.category_standings(category)
    return empty_category_standings unless category

    ordered_records = category.approved_records_ordered.to_a
    build_category_standings(category, ordered_records)
  end

  def self.standings_by_category(categories)
    category_list = Array(categories)
    return {} if category_list.empty?

    records_by_cat = grouped_approved_records(category_list.map(&:id))
    category_list.index_with do |category|
      ordered = order_category_records(category, records_by_cat[category.id] || [])
      build_category_standings(category, ordered)
    end
  end

  def self.overall_leaderboard
    Rails.cache.fetch("leaderboard_calculator/#{cache_version}/overall", expires_in: CACHE_TTL) do
      build_leaderboard(Category.active.ordered.to_a)
    end
  end

  def self.seasonal_leaderboard(season)
    return LeaderboardResult.new(entries: []) unless season

    cache_key = "leaderboard_calculator/#{cache_version}/season/#{season.id}/#{season.starts_at.to_i}_#{season.ends_at.to_i}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      build_leaderboard(season.active_categories.ordered.to_a)
    end
  end

  def self.cache_version
    Rails.cache.fetch(CACHE_VERSION_KEY, expires_in: 12.hours) do
      SecureRandom.hex(8)
    end
  end

  def self.invalidate_cache!
    Rails.cache.delete(CACHE_VERSION_KEY)
  end

  private_class_method def self.empty_category_standings
    CategoryStandings.new(
      category_id: nil,
      participants_count: 0,
      max_points: 0,
      top_entry: nil,
      entries: [],
      best_entries: []
    )
  end

  private_class_method def self.grouped_approved_records(category_ids)
    return {} if category_ids.empty?

    Record.joins(:user)
          .where(category_id: category_ids, status: "APPROVED", users: { is_active: true })
          .includes(:user)
          .group_by(&:category_id)
  end

  private_class_method def self.order_category_records(category, records)
    records.sort_by do |record|
      sort_key = category.sort_direction == "ASC" ? record.sort_value : -record.sort_value
      [ sort_key, record.created_at, record.achieved_at, record.id ]
    end
  end

  private_class_method def self.build_category_standings(category, ordered_records)
    seen_user_ids = Set.new
    personal_best_records = []

    ordered_records.each do |record|
      next if seen_user_ids.include?(record.user_id)

      seen_user_ids.add(record.user_id)
      personal_best_records << record
    end

    participants_count = personal_best_records.size
    max_points = category.is_archived? || participants_count.zero? ? 0 : points_for(participants_count, 1)
    tie_groups = personal_best_records.group_by(&:sort_value)

    best_entries = []
    best_by_record_id = {}

    personal_best_records.each_with_index do |record, index|
      rank = index + 1
      pts = category.is_archived? ? 0 : points_for(participants_count, rank)
      group = tie_groups[record.sort_value]
      is_tied = group.size > 1
      is_tied_earlier = is_tied && group.first.id == record.id

      entry = CategoryStandingEntry.new(
        record: record,
        user: record.user,
        user_id: record.user_id,
        rank: rank,
        points: pts,
        personal_best: true,
        tied_sort_value: is_tied,
        tied_earlier: is_tied_earlier
      )
      best_entries << entry
      best_by_record_id[record.id] = entry
    end

    entries = ordered_records.map do |record|
      best_by_record_id[record.id] || CategoryStandingEntry.new(
        record: record,
        user: record.user,
        user_id: record.user_id,
        rank: nil,
        points: 0,
        personal_best: false,
        tied_sort_value: false,
        tied_earlier: false
      )
    end

    CategoryStandings.new(
      category_id: category.id,
      participants_count: participants_count,
      max_points: max_points,
      top_entry: best_entries.first,
      entries: entries,
      best_entries: best_entries
    )
  end

  private_class_method def self.build_leaderboard(categories)
    return LeaderboardResult.new(entries: []) if categories.empty?

    records_by_cat = grouped_approved_records(categories.map(&:id))
    user_totals = {}

    categories.each do |category|
      ordered = order_category_records(category, records_by_cat[category.id] || [])
      standings = build_category_standings(category, ordered)
      next if standings.participants_count.zero?

      standings.best_entries.each do |standing_entry|
        user = standing_entry.user
        bucket = user_totals[user.id] ||= {
          user: user,
          total_points: 0,
          first_places_count: 0,
          categories_count: 0,
          breakdown: []
        }

        bucket[:total_points] += standing_entry.points
        bucket[:first_places_count] += 1 if standing_entry.rank == 1
        bucket[:categories_count] += 1
        bucket[:breakdown] << BreakdownItem.new(
          category_id: category.id,
          category_name: category.name,
          category_created_at: category.created_at,
          rank: standing_entry.rank,
          participants_count: standings.participants_count,
          points: standing_entry.points,
          record_id: standing_entry.record.id,
          record_value: standing_entry.record.value,
          display_value: category.display_record_value(standing_entry.record),
          achieved_at: standing_entry.record.achieved_at
        )
      end
    end

    sorted_buckets = user_totals.values.sort_by do |bucket|
      user = bucket[:user]
      [
        -bucket[:total_points],
        -bucket[:first_places_count],
        -bucket[:categories_count],
        user.created_at,
        user.id
      ]
    end

    entries = sorted_buckets.each_with_index.map do |bucket, index|
      user = bucket[:user]
      sorted_breakdown = bucket[:breakdown].sort_by do |item|
        [ -item.points, item.rank, item.category_name ]
      end

      LeaderboardEntry.new(
        rank: index + 1,
        user_id: user.id,
        username: user.username,
        display_name: user.display_name,
        user_created_at: user.created_at,
        total_points: bucket[:total_points],
        first_places_count: bucket[:first_places_count],
        categories_count: bucket[:categories_count],
        breakdown: sorted_breakdown
      )
    end

    LeaderboardResult.new(entries: entries)
  end
end
