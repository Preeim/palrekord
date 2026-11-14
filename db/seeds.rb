return if Rails.env.test?

require "zlib"
require "tempfile"

# Egyszerű, 100%-ban szabványos PNG minta igazolókép generálása külső eszköz nélkül
def build_sample_png_uploaded_file(filename, r:, g:, b:)
  width = 320
  height = 180

  png_chunk = lambda do |type, data|
    payload = type.b + data.b
    [ data.bytesize ].pack("N") + payload + [ Zlib.crc32(payload) ].pack("N")
  end

  raw_rows = String.new(encoding: Encoding::BINARY)
  height.times do |y|
    raw_rows << "\x00".b
    border = y < 12 || y >= height - 12
    stripe = (y >= 78 && y <= 102)
    width.times do |x|
      x_border = x < 12 || x >= width - 12
      if border || x_border
        raw_rows << [ 34, 34, 34 ].pack("C3")
      elsif stripe
        raw_rows << [ 255, 255, 255 ].pack("C3")
      else
        raw_rows << [ r, g, b ].pack("C3")
      end
    end
  end

  png_bytes = +"\x89PNG\r\n\x1a\n".b
  png_bytes << png_chunk.call("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("N2C5"))
  png_bytes << png_chunk.call("IDAT", Zlib::Deflate.deflate(raw_rows))
  png_bytes << png_chunk.call("IEND", "")

  tmp = Tempfile.new([ File.basename(filename, ".png"), ".png" ])
  tmp.binmode
  tmp.write(png_bytes)
  tmp.rewind

  ActionDispatch::Http::UploadedFile.new(
    tempfile: tmp,
    filename: filename,
    type: "image/png"
  )
end

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

# Minta tagok a kezdő ranglistához és bizonyítékokhoz
sample_members = [
  { username: "kovacs_peti", display_name: "Kovács Peti", email: "peti@palrekord.local" },
  { username: "nagy_bence", display_name: "Nagy Bence", email: "bence@palrekord.local" },
  { username: "toth_adam", display_name: "Tóth Ádám", email: "adam@palrekord.local" },
  { username: "szabo_anna", display_name: "Szabó Anna", email: "anna@palrekord.local" }
].each_with_object({}) do |attrs, memo|
  memo[attrs[:username]] = User.find_or_create_by!(username: attrs[:username]) do |user|
    user.display_name = attrs[:display_name]
    user.email = attrs[:email]
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = "TAG"
    user.is_active = true
    user.confirmed_at = Time.current
  end
end

# Kezdeti meghívókód új tagok regisztrációjához
InviteCode.find_or_create_by!(code: "PAL-8F3K9A") do |invite|
  invite.label = "Kezdeti baráti meghívókód"
  invite.is_active = true
  invite.created_by = admin
end

# Minta szezonális verseny
Season.find_or_create_by!(name: "2026 Őszi Szezon") do |season|
  season.starts_at = Time.zone.local(2026, 9, 1, 0, 0, 0)
  season.ends_at = Time.zone.local(2026, 11, 30, 23, 59, 59)
  season.created_by = admin
end

# Kezdő versenyszámok egyszerű, védhető verifikációs ajánlásokkal
sample_categories = [
  {
    name: "100m sörfutás",
    description: "100 méteres sprintfutás egy pohár sörrel a kézben. Minél gyorsabb, annál jobb.",
    unit: "mp",
    value_type: "TIME_DURATION",
    sort_direction: "ASC",
    recommended_file_type: "LINK",
    verification_hint: "Vágatlan telefonos videó a rajtról, a pohár sörről és a célba érésről (pl. Google Fotók / YouTube Shorts link), vagy célfotó a stopperóráról + tanú."
  },
  {
    name: "Fekvenyomás max",
    description: "Egy ismétléses maximum szabályos fekvenyomásból.",
    unit: "kg",
    value_type: "DOUBLE",
    sort_direction: "DESC",
    recommended_file_type: "IMAGE",
    verification_hint: "1 fotó a felpakolt rúdról, amelyen tisztán leolvashatók a súlytárcsák (kg) feliratai (+ spotter/tanú neve a megjegyzésben)."
  },
  {
    name: "Legtöbb megevett palacsinta",
    description: "Együltő helyben elfogyasztott palacsinták száma.",
    unit: "db",
    value_type: "INT",
    sort_direction: "DESC",
    recommended_file_type: "TEXT",
    verification_hint: "Tanú-jegyzőkönyv legalább 2 jelenlévő barát nevével és a helyszínnel, vagy fotó a strigulázott számlálólapról és az üres tányérról."
  },
  {
    name: "Planking kitartás",
    description: "Szabályos alkartámasz (plank) tartás időméréssel.",
    unit: "perc",
    value_type: "TIME_DURATION",
    sort_direction: "DESC",
    recommended_file_type: "IMAGE",
    verification_hint: "Fotó vagy képernyőkép a telefon stopperóráról / okosóra edzés-összesítőjéről közvetlenül a plank befejezésekor (+ tanú neve)."
  },
  {
    name: "Rubik-kocka 3x3",
    description: "Klasszikus 3x3-as Rubik-kocka kirakása kevert állapotból.",
    unit: "mp",
    value_type: "DOUBLE",
    sort_direction: "ASC",
    recommended_file_type: "IMAGE",
    verification_hint: "1 közös fotó, amelyen egyszerre látszik a kirakott Rubik-kocka és mellette a timer kijelzője (pl. csTimer idővel és keverési kóddal)."
  }
]

categories_by_name = {}
sample_categories.each do |attrs|
  category = Category.find_or_initialize_by(name: attrs[:name])
  category.assign_attributes(
    description: attrs[:description],
    unit: attrs[:unit],
    value_type: attrs[:value_type],
    sort_direction: attrs[:sort_direction],
    recommended_file_type: attrs[:recommended_file_type],
    verification_hint: attrs[:verification_hint]
  )
  category.created_by ||= admin
  category.save!
  categories_by_name[attrs[:name]] = category
end

# Minta rekordok és valódi, megnyitható verifikációs bizonyítékok minden kezdő kategóriához
sample_records = [
  {
    category: "100m sörfutás",
    username: "kovacs_peti",
    value: "18.42",
    achieved_at: Date.new(2026, 11, 5),
    note: "Kollégium mögötti salakpálya, 0.5l csapolt sörrel, tanú: Nagy Bence",
    attachment: {
      file_type: "LINK",
      file_path_or_url: "https://example.com/palrekord-demo/100m-sorfutas-1842"
    }
  },
  {
    category: "100m sörfutás",
    username: "toth_adam",
    value: "20.15",
    achieved_at: Date.new(2026, 11, 6),
    note: "Célban fotózott stopperóra, tanú: Szabó Anna",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "stopper_sorfutas_2015.png", 219, 234, 254 ]
    }
  },
  {
    category: "Fekvenyomás max",
    username: "nagy_bence",
    value: "125.0",
    achieved_at: Date.new(2026, 11, 7),
    note: "20 kg olimpiai rúd + oldalanként 20+20+12.5 kg, spotter: Kovács Peti",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "sulytarcsa_fekvenyomas_125kg.png", 220, 252, 231 ]
    }
  },
  {
    category: "Fekvenyomás max",
    username: "kovacs_peti",
    value: "110.0",
    achieved_at: Date.new(2026, 11, 8),
    note: "Spotter: Nagy Bence",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "sulytarcsa_fekvenyomas_110kg.png", 226, 232, 240 ]
    }
  },
  {
    category: "Legtöbb megevett palacsinta",
    username: "toth_adam",
    value: "19",
    achieved_at: Date.new(2026, 11, 9),
    note: "Kakaós és lekváros palacsinta, két tanúval hitelesítve",
    attachment: {
      file_type: "TEXT",
      text_content: "Jelenlévő tanú(k): Kovács Peti, Szabó Anna\nHelyszín és időpont: Koliszint 3 közösségi konyha, 2026-11-09 20:30\nMérés módja / eszköz: Papír strigula minden tányérra szedéskor, 2 üres tál ellenőrizve"
    }
  },
  {
    category: "Legtöbb megevett palacsinta",
    username: "szabo_anna",
    value: "14",
    achieved_at: Date.new(2026, 11, 9),
    note: "Strigulázott számlálólap fotózva",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "strigulalap_palacsinta_14db.png", 254, 249, 195 ]
    }
  },
  {
    category: "Planking kitartás",
    username: "szabo_anna",
    value: "04:12.00",
    achieved_at: Date.new(2026, 11, 10),
    note: "Telefon stopperóra képernyőkép, tanú: Tóth Ádám",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "stopper_planking_0412.png", 224, 242, 254 ]
    }
  },
  {
    category: "Rubik-kocka 3x3",
    username: "nagy_bence",
    value: "34.10",
    achieved_at: Date.new(2026, 11, 11),
    note: "Kirakott kocka és csTimer kijelző (scramble: R U2 B' L2 D F') egy közös fotón",
    attachment: {
      file_type: "IMAGE",
      sample_png: [ "rubik_kocka_cstimer_3410.png", 237, 233, 254 ]
    }
  }
]

sample_records.each do |item|
  category = categories_by_name.fetch(item[:category])
  member = sample_members.fetch(item[:username])

  record = Record.find_or_initialize_by(
    category: category,
    user: member,
    value: item[:value]
  )
  record.assign_attributes(
    achieved_at: item[:achieved_at],
    note: item[:note],
    status: "APPROVED",
    reviewed_by: admin,
    reviewed_at: Time.current
  )
  record.save!

  next if record.attachments.exists?

  att_spec = item[:attachment]
  case att_spec[:file_type]
  when "IMAGE"
    filename, r, g, b = att_spec[:sample_png]
    uploaded = build_sample_png_uploaded_file(filename, r: r, g: g, b: b)
    begin
      Attachment.create!(record: record, file_type: "IMAGE", uploaded_file: uploaded)
    ensure
      uploaded&.tempfile&.close!
    end
  when "LINK"
    Attachment.create!(record: record, file_type: "LINK", file_path_or_url: att_spec[:file_path_or_url])
  when "TEXT"
    Attachment.create!(record: record, file_type: "TEXT", text_content: att_spec[:text_content])
  end
end
