#!/bin/bash
set -e

export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$HOME/.local/share/mise/shims:$HOME/.asdf/shims:/usr/local/bin:$PATH"
[ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm"

echo "=== Deploy inditasa: $(date) ==="

git fetch origin main
git reset --hard origin/main

bundle install
bin/rails db:prepare

echo "=== Webszerver ujrainditasa ==="
pkill -f "puma" || true
sleep 1
nohup bin/rails server -b 0.0.0.0 -p 3000 > log/puma.log 2>&1 < /dev/null &

echo "=== Sikeres Deploy! ==="
