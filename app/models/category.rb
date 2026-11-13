class Category < ApplicationRecord
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

  scope :active, -> { where(is_archived: false) }
  scope :ordered, -> { order(is_archived: :asc, name: :asc) }

  def sort_by_label
    "#{value_type} · #{sort_direction}"
  end

  def approved_records_ordered
    direction = sort_direction == "ASC" ? :asc : :desc
    records.where(status: "APPROVED")
           .includes(:user, :attachments)
           .order(sort_value: direction, achieved_at: :asc, id: :asc)
  end

  def top_record
    approved_records_ordered.first
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
end
