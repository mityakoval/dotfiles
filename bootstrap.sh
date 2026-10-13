#!/usr/bin/env bash
# Sets up this machine from the dotfiles repo. Safe to re-run.
#
#   ./bootstrap.sh            # everything
#   ./bootstrap.sh --no-pkgs  # skip installing packages from pkglist/
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

PACKAGES=(hypr kitty nvim zsh noctalia theming systemd btop fastfetch cava aerc openrgb gaming wallpapers yay)

install_pkgs=1
[[ "${1:-}" == "--no-pkgs" ]] && install_pkgs=0

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "Installing the tools this repo needs"
sudo pacman -S --needed --noconfirm stow git git-lfs gitleaks

if (( install_pkgs )); then
    step "Installing official packages from pkglist/native.txt"
    sudo pacman -S --needed - < pkglist/native.txt

    step "Installing AUR packages from pkglist/aur.txt"
    if ! command -v yay >/dev/null; then
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    yay -S --needed - < pkglist/aur.txt
fi

step "Enabling git hooks (gitleaks pre-commit + Git LFS)"
git config core.hooksPath hooks   # before `lfs install`, so LFS uses the tracked hooks/

step "Fetching wallpapers (Git LFS)"
git lfs install --local
git lfs pull

step "Installing oh-my-zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    # --keep-zshrc: don't overwrite ours; --unattended: don't switch shell or start zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

step "Linking configs with stow"
for pkg in "${PACKAGES[@]}"; do
    echo "  $pkg"
    stow --restow "$pkg"   # options come from .stowrc
done

step "Enabling systemd user units"
systemctl --user daemon-reload
systemctl --user enable prtscr-remap.service

step "Installing the pacman hook that keeps pkglist/ up to date"
sed -e "s|@USER@|$USER|" -e "s|@DOTFILES@|$DOTFILES|" system/pkglist.hook.in \
    | sudo install -Dm644 /dev/stdin /etc/pacman.d/hooks/dotfiles-pkglist.hook

step "Enabling weekly pacman cache cleanup (paccache, keeps 3 versions)"
sudo systemctl enable --now paccache.timer

if [[ ! -f "$HOME/.zshrc.local" ]]; then
    step "Creating an empty ~/.zshrc.local for secrets"
    install -m600 /dev/null "$HOME/.zshrc.local"
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
    step "Switching login shell to zsh"
    chsh -s /usr/bin/zsh
fi

step "Done. Log out and back in to pick everything up."
