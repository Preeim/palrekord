#!/bin/bash
set -e

# Ruby verziókezelők (rbenv / rvm / asdf / mise) betöltése nem-interaktív shellben is
export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.local/share/mise/shims:$HOME/.asdf/shims:/usr/local/bin:$PATH"
[ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm"

echo "=== Deploy inditasa: $(date) ==="

git fetch origin main
git reset --hard origin/main

bundle install
bin/rails db:migrate

echo "=== Sikeres Deploy! ==="
