#!/usr/bin/env bash
# Regenerates the package lists. Run by the pacman hook after every
# install/remove; safe to run by hand too.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pacman -Qqen > "$dir/native.txt"   # explicitly installed, from official repos
pacman -Qqem > "$dir/aur.txt"      # explicitly installed, foreign (AUR)
