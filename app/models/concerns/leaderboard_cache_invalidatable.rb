module LeaderboardCacheInvalidatable
  extend ActiveSupport::Concern

  included do
    after_save :invalidate_leaderboard_cache
    after_destroy :invalidate_leaderboard_cache
    after_commit :invalidate_leaderboard_cache
    after_rollback :invalidate_leaderboard_cache
  end

  private

  def invalidate_leaderboard_cache
    LeaderboardCalculator.invalidate_cache!
  end
end
