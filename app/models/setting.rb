class Setting < ApplicationRecord
  DEFAULTS = {
    "email_system" => {
      value: "false",
      description: "SMTP / e-mail megerősítés és önkiszolgáló jelszó-reset engedélyezése."
    },
    "require_invite_code" => {
      value: "true",
      description: "Regisztrációhoz kötelező-e érvényes meghívókód."
    },
    "public_leaderboards" => {
      value: "true",
      description: "Vendégek (nem belépve) láthatják-e a ranglistákat és verifikációkat."
    },
    "members_can_create_categories" => {
      value: "false",
      description: "Tagok létrehozhatnak-e új versenyszámot (egyébként csak Admin)."
    },
    "require_record_approval" => {
      value: "true",
      description: "Beküldött rekordok előzetes admin jóváhagyásra várjanak-e (PENDING)."
    }
  }.freeze

  validates :key, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :value, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 255 }, allow_nil: true

  def self.get(key)
    key_str = key.to_s
    find_by(key: key_str)&.value || DEFAULTS.dig(key_str, :value)
  end

  def self.get_bool(key)
    get(key).to_s.downcase == "true"
  end

  def self.set(key, value)
    key_str = key.to_s
    setting = find_or_initialize_by(key: key_str)
    setting.value = value.to_s
    setting.description ||= DEFAULTS.dig(key_str, :description)
    setting.save!
    setting
  end

  def self.ensure_defaults!
    DEFAULTS.each do |key, attrs|
      find_or_create_by!(key: key) do |setting|
        setting.value = attrs[:value]
        setting.description = attrs[:description]
      end
    end
  end

  def self.email_system?
    get_bool("email_system")
  end

  def self.require_invite_code?
    get_bool("require_invite_code")
  end

  def self.public_leaderboards?
    get_bool("public_leaderboards")
  end

  def self.members_can_create_categories?
    get_bool("members_can_create_categories")
  end

  def self.require_record_approval?
    get_bool("require_record_approval")
  end

  def boolean_value?
    value.to_s.downcase == "true"
  end
end
