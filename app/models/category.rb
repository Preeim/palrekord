class Category < ApplicationRecord
  include LeaderboardCacheInvalidatable

  VALUE_TYPES = %w[INT DOUBLE TIME_DURATION DATE].freeze
  SORT_DIRECTIONS = %w[ASC DESC].freeze

  belongs_to :created_by, class_name: "User", optional: true
  has_many :records, dependent: :destroy

  normalizes :name, with: ->(value) { value.to_s.strip }
  normalizes :unit, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 150 }
  validates :unit, presence: true, length: { maximum: 30 }
  validates :value_type, presence: true, inclusion: { in: VALUE_TYPES }
  validates :sort_direction, presence: true, inclusion: { in: SORT_DIRECTIONS }
  validate :creator_must_have_monthly_quota, on: :create

  scope :active, -> { where(is_archived: false) }
  scope :ordered, -> { order(is_archived: :asc, name: :asc) }

  def sort_by_label
    "#{value_type} · #{sort_direction}"
  end

  def approved_records_ordered
    direction = sort_direction == "ASC" ? :asc : :desc
    records.joins(:user)
           .where(status: "APPROVED", users: { is_active: true })
           .includes(:user, :attachments)
           .order(sort_value: direction, created_at: :asc, achieved_at: :asc, id: :asc)
  end

  def top_record
    approved_records_ordered.first
  end

  def matching_season(seasons_list = nil)
    return nil if created_at.blank?

    if seasons_list
      seasons_list.find { |season| season.starts_at <= created_at && season.ends_at >= created_at }
    else
      Season.where("starts_at <= ? AND ends_at >= ?", created_at, created_at)
            .order(starts_at: :desc, id: :desc)
            .first
    end
  end

  def display_record_value(record)
    return "" unless record

    if value_type == "TIME_DURATION" && record.value.include?(":")
      record.value
    elsif unit.present? && unit != "-"
      "#{record.value} #{unit}"
    else
      record.value
    end
  end

  private

  def creator_must_have_monthly_quota
    return unless created_by.present? && !created_by.admin?

    reference_time = created_at || Time.current
    return if created_by.category_quota_available?(reference_time)

    limit = Setting.monthly_category_limit
    reset_date = created_by.next_category_quota_reset_date(reference_time).strftime("%Y-%m-%d")
    errors.add(:base, "Elérted a havi kategória-létrehozási kvótádat (0 / #{limit} elérhető ebben a hónapban). Következő nyitás: #{reset_date}.")
  end
end
