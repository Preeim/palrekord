class Season < ApplicationRecord
  include LeaderboardCacheInvalidatable

  belongs_to :created_by, class_name: "User", optional: true

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, length: { maximum: 120 }, uniqueness: { case_sensitive: false }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_at_must_be_after_starts_at

  scope :ordered, -> { order(starts_at: :desc, id: :desc) }
  scope :active_at, ->(time = Time.current) { where("starts_at <= ? AND ends_at >= ?", time, time).order(starts_at: :desc, id: :desc) }

  def self.current(time = Time.current)
    active_at(time).first
  end

  def active?(time = Time.current)
    starts_at <= time && ends_at >= time
  end

  def ended?(time = Time.current)
    ends_at < time
  end

  def upcoming?(time = Time.current)
    starts_at > time
  end

  def status_label(time = Time.current)
    if active?(time)
      "Aktív"
    elsif ended?(time)
      "Lezárt"
    else
      "Közelgő"
    end
  end

  def categories
    Category.where(created_at: starts_at..ends_at)
  end

  def active_categories
    Category.active.where(created_at: starts_at..ends_at)
  end

  def period_label
    "#{starts_at.strftime('%Y-%m-%d')} – #{ends_at.strftime('%Y-%m-%d')}"
  end

  private

  def ends_at_must_be_after_starts_at
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "későbbi kell legyen, mint a szezon kezdete")
  end
end
