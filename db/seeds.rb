return if Rails.env.test?

# Alapértelmezett rendszerbeállítások
Setting.ensure_defaults!

# Kezdeti Admin felhasználó (ha még nem létezik)
admin = User.find_or_create_by!(username: "admin") do |user|
  user.display_name = "Adminisztrátor"
  user.email = "admin@palrekord.local"
  user.password = "admin12345"
  user.password_confirmation = "admin12345"
  user.role = "ADMIN"
  user.is_active = true
  user.confirmed_at = Time.current
end

# Kezdeti meghívókód új tagok regisztrációjához
InviteCode.find_or_create_by!(code: "PAL-8F3K9A") do |invite|
  invite.label = "Kezdeti baráti meghívókód"
  invite.is_active = true
  invite.created_by = admin
end

# Minta versenyszámok a látványterv alapján
sample_categories = [
  {
    name: "100m sörfutás",
    description: "100 méteres sprintfutás egy pohár sörrel a kézben. Minél gyorsabb, annál jobb.",
    unit: "mp",
    value_type: "TIME_DURATION",
    sort_direction: "ASC"
  },
  {
    name: "Fekvenyomás max",
    description: "Egy ismétléses maximum szabályos fekvenyomásból.",
    unit: "kg",
    value_type: "DOUBLE",
    sort_direction: "DESC"
  },
  {
    name: "Legtöbb megevett palacsinta",
    description: "Együltő helyben elfogyasztott palacsinták száma.",
    unit: "db",
    value_type: "INT",
    sort_direction: "DESC"
  },
  {
    name: "Planking kitartás",
    description: "Szabályos alkartámasz (plank) tartás időméréssel.",
    unit: "perc",
    value_type: "TIME_DURATION",
    sort_direction: "DESC"
  },
  {
    name: "Rubik-kocka 3x3",
    description: "Klasszikus 3x3-as Rubik-kocka kirakása kevert állapotból.",
    unit: "mp",
    value_type: "DOUBLE",
    sort_direction: "ASC"
  }
]

sample_categories.each do |attrs|
  Category.find_or_create_by!(name: attrs[:name]) do |category|
    category.description = attrs[:description]
    category.unit = attrs[:unit]
    category.value_type = attrs[:value_type]
    category.sort_direction = attrs[:sort_direction]
    category.created_by = admin
  end
end
