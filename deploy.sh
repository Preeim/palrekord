#!/bin/bash
set -e

# Környezeti változók betöltése (rbenv/rvm/path)
[ -f ~/.profile ] && source ~/.profile
[ -f ~/.bashrc ] && source ~/.bashrc

echo "=== Deploy inditasa: $(date) ==="

git fetch origin main
git reset --hard origin/main

bundle install
bin/rails db:migrate

echo "=== Sikeres Deploy! ==="
