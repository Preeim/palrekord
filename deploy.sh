#!/bin/bash
set -e # Ha bármelyik parancs hibára fut, a script azonnal álljon le!

echo "=== 🚀 Deploy indítása: $(date) ==="

# 1. Kód frissítése a GitHubról
echo "📥 Kód letöltése..."
git fetch origin main
git reset --hard origin/main

# 2. Függőségek telepítése
echo "📦 Gemek telepítése..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# 3. Adatbázis migrációk futtatása
echo "🗄️ Adatbázis migráció..."
RAILS_ENV=production bundle exec rails db:migrate

# 4. Assetek előfordítása
echo "🎨 Statikus fájlok (assets) precompile..."
RAILS_ENV=production bundle exec rails assets:precompile

# 5. Alkalmazás újraindítása
echo "🔄 Szerver újraindítása..."
if systemctl is-active --quiet uj_projekt; then
    sudo systemctl restart uj_projekt
else
    # Ha még fejlesztői módban / sima processzként tesztelsz:
    pkill -f "puma" || true
    echo "Puma leállítva, indítsd újra vagy állítsd be a systemd szervizt!"
fi

echo "=== ✅ Sikeres Deploy! ==="
