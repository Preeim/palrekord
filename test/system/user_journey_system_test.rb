require "application_system_test_case"

class UserJourneySystemTest < ApplicationSystemTestCase
  setup do
    Setting.ensure_defaults!

    @admin = User.create!(
      username: "sysadmin",
      display_name: "Rendszer Admin",
      email: "sysadmin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "ADMIN",
      confirmed_at: Time.current
    )

    @invite = InviteCode.create!(
      code: "PAL-SYS001",
      max_uses: 5,
      is_active: true,
      created_by: @admin
    )

    @category = Category.create!(
      name: "Fekvenyomás max",
      unit: "kg",
      value_type: "DOUBLE",
      sort_direction: "DESC",
      created_by: @admin
    )
  end

  test "full user UI journey: register, submit record, admin approves, and leaderboard updates" do
    visit root_path
    assert_text "Fekvenyomás max"
    assert_text "Bejelentkezés"
    assert_text "Regisztráció"

    # Register via UI
    click_link "Regisztráció"
    fill_in "Felhasználónév *", with: "ujbajnok"
    fill_in "Megjelenített név (becenév) *", with: "Új Bajnok"
    fill_in "Jelszó * (min. 8 karakter)", with: "password123"
    fill_in "Jelszó megerősítése *", with: "password123"
    fill_in "Meghívókód *", with: "PAL-SYS001"
    click_button "Fiók létrehozása"

    assert_text "Sikeres regisztráció!"
    assert_text "Profil (Új Bajnok · 0 pt)"

    # Submit a record via UI
    click_link "+ Új rekord"
    select "Fekvenyomás max (kg · Tört vagy egész szám (pl. 125.0))", from: "Versenyszám *"
    fill_in "Elért érték *", with: "110.5"
    fill_in "Megjegyzés / tanúk", with: "Edzőteremben mérve"
    select "Szöveges igazolás (TEXT)", from: "Melléklet típusa"
    fill_in "Szöveges igazolás (TEXT esetén)", with: "Peti és Anna látta"
    click_button "Rekord beküldése"

    assert_text "Rekord beküldve, adminisztrátori jóváhagyásra vár."
    assert_text "Függőben"

    # Log out and log in as Admin
    click_button "Kijelentkezés"
    click_link "Bejelentkezés"
    fill_in "Felhasználónév vagy e-mail", with: "sysadmin"
    fill_in "Jelszó", with: "password123"
    click_button "Belépés"

    # Approve the pending record in Admin panel
    click_link "Admin"
    assert_text "Új Bajnok"
    assert_text "110.5 kg"
    click_button "Jóváhagyás"
    assert_text "jóváhagyva"

    # Verify points appear on homepage leaderboard and category page
    visit root_path
    assert_text "Új Bajnok"
    assert_text "1 pt"

    click_link "Fekvenyomás max"
    assert_text "110.5 kg"
    assert_text "+1 pt"
    assert_text "Peti és Anna látta"
  end
end
