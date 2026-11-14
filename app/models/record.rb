require "bigdecimal"

class Record < ApplicationRecord
  include LeaderboardCacheInvalidatable

  STATUSES = %w[PENDING APPROVED REJECTED].freeze

  belongs_to :user
  belongs_to :category
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :attachments, dependent: :destroy

  accepts_nested_attributes_for :attachments,
    allow_destroy: true,
    reject_if: ->(attrs) {
      attrs["file_type"].blank? &&
        attrs["uploaded_file"].blank? &&
        attrs["file_path_or_url"].blank? &&
        attrs["text_content"].blank?
    }

  before_validation :normalize_and_compute_sort_value

  validates :value, presence: true, length: { maximum: 100 }
  validates :sort_value, presence: true, numericality: true
  validates :achieved_at, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :category_must_not_be_archived, if: -> { new_record? || category_id_changed? }

  scope :pending, -> { where(status: "PENDING") }
  scope :approved, -> { where(status: "APPROVED") }
  scope :rejected, -> { where(status: "REJECTED") }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def pending?
    status == "PENDING"
  end

  def approved?
    status == "APPROVED"
  end

  def rejected?
    status == "REJECTED"
  end

  private

  def category_must_not_be_archived
    return unless category&.is_archived?

    errors.add(:category, "archivált, új rekord nem küldhető be ebbe a versenyszámba")
  end

  def normalize_and_compute_sort_value
    return if value.blank? || category.blank?

    raw = value.to_s.strip
    self.value = raw

    case category.value_type
    when "INT"
      parse_int_value(raw)
    when "DOUBLE"
      parse_double_value(raw)
    when "TIME_DURATION"
      parse_time_duration_value(raw)
    when "DATE"
      parse_date_value(raw)
    end
  end

  def parse_int_value(raw)
    unless raw.match?(/\A[+-]?\d+\z/)
      errors.add(:value, "egész számnak kell lennie (pl. 19)")
      return
    end

    self.sort_value = BigDecimal(raw)
  end

  def parse_double_value(raw)
    normalized = raw.tr(",", ".")
    unless normalized.match?(/\A[+-]?\d+(?:\.\d+)?\z/)
      errors.add(:value, "valós számnak kell lennie (pl. 125.0)")
      return
    end

    self.value = normalized
    self.sort_value = BigDecimal(normalized)
  end

  def parse_time_duration_value(raw)
    normalized = raw.tr(",", ".")

    if normalized.match?(/\A\d+(?:\.\d+)?\z/)
      self.value = normalized
      self.sort_value = BigDecimal(normalized).round(4)
      return
    end

    if (match = normalized.match(/\A(\d+):(\d{1,2}(?:\.\d+)?)\z/))
      minutes = match[1].to_i
      seconds = BigDecimal(match[2])
      if seconds >= 60
        errors.add(:value, "az időformátumban a másodperc 60-nál kisebb kell legyen")
        return
      end

      self.value = normalized
      self.sort_value = (BigDecimal(minutes * 60) + seconds).round(4)
      return
    end

    if (match = normalized.match(/\A(\d+):(\d{1,2}):(\d{1,2}(?:\.\d+)?)\z/))
      hours = match[1].to_i
      minutes = match[2].to_i
      seconds = BigDecimal(match[3])
      if minutes >= 60 || seconds >= 60
        errors.add(:value, "az időformátumban a perc és másodperc 60-nál kisebb kell legyen")
        return
      end

      self.value = normalized
      self.sort_value = (BigDecimal(hours * 3600 + minutes * 60) + seconds).round(4)
      return
    end

    errors.add(:value, "érvénytelen időformátum (pl. 18.42, 04:12.00 vagy 01:02:03.4)")
  end

  def parse_date_value(raw)
    unless raw.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      errors.add(:value, "dátum formátuma ÉÉÉÉ-HH-NN kell legyen (pl. 2026-11-13)")
      return
    end

    parsed = Date.iso8601(raw)
    self.sort_value = BigDecimal(parsed.jd)
  rescue Date::Error
    errors.add(:value, "érvénytelen naptári dátum")
  end
end
