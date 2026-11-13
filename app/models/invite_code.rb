class InviteCode < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :users, dependent: :nullify

  normalizes :code, with: ->(value) { value.to_s.strip.upcase }
  normalizes :label, with: ->(value) { value.to_s.strip.presence }

  before_validation :generate_code_if_blank, on: :create

  validates :code, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 64 }
  validates :label, length: { maximum: 100 }, allow_nil: true
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :uses_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :newest_first, -> { order(created_at: :desc) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def exhausted?
    max_uses.present? && uses_count >= max_uses
  end

  def usable?
    is_active? && !expired? && !exhausted?
  end

  def usage_summary
    max_uses.present? ? "#{uses_count} / #{max_uses}" : "#{uses_count} / ∞"
  end

  private

  def generate_code_if_blank
    return if code.present?

    loop do
      candidate = "PAL-#{SecureRandom.alphanumeric(6).upcase}"
      unless self.class.exists?(code: candidate)
        self.code = candidate
        break
      end
    end
  end
end
