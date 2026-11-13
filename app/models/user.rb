class User < ApplicationRecord
  ROLES = %w[TAG ADMIN].freeze

  has_secure_password

  belongs_to :invite_code, optional: true
  has_many :records, dependent: :destroy
  has_many :reviewed_records, class_name: "Record", foreign_key: :reviewed_by_id, dependent: :nullify
  has_many :created_invite_codes, class_name: "InviteCode", foreign_key: :created_by_id, dependent: :nullify
  has_many :created_categories, class_name: "Category", foreign_key: :created_by_id, dependent: :nullify

  normalizes :username, with: ->(value) { value.to_s.strip.downcase }
  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :display_name, with: ->(value) { value.to_s.strip }

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  validates :username,
    presence: true,
    length: { in: 3..50 },
    uniqueness: { case_sensitive: false },
    format: { without: /@|\s/, message: "nem tartalmazhat '@' jelet vagy szóközt" }

  validates :display_name, presence: true, length: { in: 2..100 }
  validates :email,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP },
    allow_nil: true
  validates :email, presence: true, if: -> { Setting.email_system? && (new_record? || email_changed? || email_was.present?) }

  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: ROLES }

  scope :active, -> { where(is_active: true) }
  scope :admins, -> { where(role: "ADMIN") }

  def self.authenticate_by_login(login, password)
    normalized = login.to_s.strip.downcase
    return nil if normalized.blank? || password.blank?

    if normalized.include?("@")
      authenticate_by(email: normalized, password: password)
    else
      authenticate_by(username: normalized, password: password)
    end
  end

  def admin?
    role == "ADMIN"
  end

  def tag?
    role == "TAG"
  end

  def confirmed?
    confirmed_at.present?
  end

  def last_active_admin?
    admin? && is_active? && User.active.admins.where.not(id: id).none?
  end
end
