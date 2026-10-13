# dotfiles

Configs for my Arch Linux + Hyprland + [noctalia](https://github.com/noctalia-dev/noctalia-shell) desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/).

| Package | What it links into `~` |
|---|---|
| `hypr` | `~/.config/hypr/` — `hyprland.lua`, `noctalia.lua` (generated theme), `scripts/` |
| `kitty` | `~/.config/kitty/` |
| `nvim` | `~/.config/nvim/` (kickstart.nvim-based; history imported from `mityakoval/kickstart.nvim`) |
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.profile` |
| `noctalia` | `~/.config/noctalia/` settings, colors, plugin list + plugin settings, `~/.config/noctalia-config.toml` |
| `theming` | GTK 3/4 and Qt 5/6 (`qt5ct`, `qt6ct`) colour config |
| `systemd` | user units in `~/.config/systemd/user/` |
| `btop`, `fastfetch`, `cava`, `aerc`, `openrgb` | their `~/.config/<app>/` |
| `gaming` | MangoHud, goverlay, `~/gamemode.ini` |
| `wallpapers` | `~/Pictures/Wallpapers/` (stored with Git LFS) |

Not stow packages: `pkglist/` (installed packages), `system/` (files for `/etc`), `hooks/` (git hooks), `bootstrap.sh`.

---

## How Stow works (the 2-minute version)

Programs read their config from fixed places, e.g. kitty reads `~/.config/kitty/kitty.conf`.
This repo lives in `~/dotfiles`. Stow connects the two with **symlinks** — small "pointer" files that say "the real file is over there".

Each top-level folder in the repo is a **package**. Inside a package, the folder layout **mirrors your home directory**:

```
~/dotfiles/kitty/.config/kitty/kitty.conf
          └─┬─┘ └──────────┬──────────┘
         package    path relative to ~
```

Running `stow kitty` (from `~/dotfiles`) creates:

```
~/.config/kitty/kitty.conf  ->  ~/dotfiles/kitty/.config/kitty/kitty.conf
```

kitty opens the symlink and transparently gets the file from the repo. So:

- **Editing `~/.config/kitty/kitty.conf` edits the file in the repo.** `git status` in `~/dotfiles` shows the change immediately. There is no "sync" step.
- Deleting the repo would break your configs (the symlinks would point at nothing). Don't move `~/dotfiles` without re-stowing.

You can see a link with `ls -l`:

```console
$ ls -l ~/.config/kitty/kitty.conf
lrwxrwxrwx ... /home/mitya/.config/kitty/kitty.conf -> ../../dotfiles/kitty/.config/kitty/kitty.conf
```

### Why there's a `.stowrc`

`.stowrc` holds options stow reads automatically when run from `~/dotfiles`:

- `--target=~` — link into the home directory (this is also the default because `~/dotfiles` sits in `~`, but being explicit is safer).
- `--no-folding` — link **individual files**, never whole folders. Without it, stow would make `~/.config/noctalia` itself a symlink, and every cache/log file the app writes there would land inside the repo. With it, `~/.config/noctalia/` stays a real folder; only the files we track are symlinks, and anything else the app writes stays out of git.

The flip side of `--no-folding`: **a new file you create in `~/.config/<app>/` is NOT automatically in the repo.** See "Adding a new file" below.

---

## Fresh install

```sh
git clone git@github.com:mityakoval/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` is safe to re-run. It:

1. installs `stow`, `git-lfs`, `gitleaks`;
2. installs every package in `pkglist/native.txt` (pacman) and `pkglist/aur.txt` (yay, bootstrapping yay if needed) — skip with `--no-pkgs`;
3. downloads the wallpapers from Git LFS;
4. installs oh-my-zsh (keeping our `.zshrc`);
5. stows every package;
6. enables the systemd user units;
7. installs the pacman hook that keeps `pkglist/` current;
8. enables the gitleaks pre-commit hook;
9. creates an empty `~/.zshrc.local` and switches your shell to zsh.

Then put your secrets in `~/.zshrc.local` (see [Secrets](#secrets)) and log out/in.

> **If stow refuses with "existing target is neither a link nor a directory"**: a real file is already where a link should go (common on a fresh system — e.g. a default `~/.zshrc`). Either delete it, or use `stow --adopt <pkg>` — see below.

---

## Everyday workflow

### Changing a config

Just edit it where it lives (`~/.config/...`), then commit:

```sh
cd ~/dotfiles
git status          # see what changed
git diff
git add -A && git commit -m "kitty: bigger font"
git push
```

### Adding a new file to an existing package

Because of `--no-folding`, a new file isn't tracked until you move it into the repo:

```sh
# e.g. you created ~/.config/hypr/scripts/new-thing
mv ~/.config/hypr/scripts/new-thing ~/dotfiles/hypr/.config/hypr/scripts/
cd ~/dotfiles && stow --restow hypr        # puts a symlink back in its place
```

### Adding a whole new app (new package)

Example: start tracking `~/.config/yazi/`.

```sh
cd ~/dotfiles
mkdir -p yazi/.config                       # mirror the path under ~
mv ~/.config/yazi yazi/.config/             # move the real files into the repo
stow yazi                                   # link them back
```

Then add `yazi` to the `PACKAGES=(...)` list in `bootstrap.sh` and commit.

Alternative using `--adopt` (stow moves the files for you):

```sh
mkdir -p yazi/.config/yazi
touch yazi/.config/yazi/yazi.toml           # create placeholders with the same names
stow --adopt yazi                           # stow REPLACES the placeholders with your real files, then links
git diff                                    # check what got adopted
```

`--adopt` overwrites the repo's copy with whatever is on disk, so always `git diff` afterwards.

### Removing a package

```sh
cd ~/dotfiles
stow -D waybar      # delete the symlinks (the files in the repo stay)
```

To keep the config on disk but stop tracking it, copy the files back after `stow -D`, then `git rm -r <pkg>`.

### Re-linking everything

If things look off (e.g. after moving files around in the repo):

```sh
cd ~/dotfiles
stow --restow */    # or: ./bootstrap.sh --no-pkgs
```

`--restow` removes and recreates the package's links, cleaning up dangling ones.

### Dry run

Add `-n -v` to any stow command to see what it *would* do without touching anything:

```sh
stow -n -v --restow hypr
```

---

## Troubleshooting

**`WARNING! stowing X would cause conflicts: existing target is neither a link nor a directory: .config/foo/bar`**
A real file exists where stow wants to put a link. Decide which version you want:
- keep the repo's version → delete the file in `~`, re-run `stow`;
- keep the on-disk version → `stow --adopt X`, then `git diff` to review.

**A config change "doesn't stick" / `git status` shows nothing after editing**
The file in `~` is no longer a symlink — some apps save by writing a new file and replacing the old one, which turns the link into a regular file. Check with `ls -l`. Fix:

```sh
cd ~/dotfiles
cp ~/.config/<app>/<file> <pkg>/.config/<app>/<file>   # keep your latest edits
rm ~/.config/<app>/<file>
stow --restow <pkg>
```

Find all such broken-out files at once with `stow -n -v --restow */` — any conflicts it reports are files that stopped being links.

**Dangling links after deleting a file from the repo**
`stow --restow <pkg>` removes links that point at nothing.

---

## noctalia-generated files

noctalia writes theme files generated from the current colour scheme:
`hypr/noctalia.lua`, `kitty/themes/noctalia.conf`, `gtk-{3,4}.0/noctalia.css`, `qt{5,6}ct/colors/noctalia.conf`, `noctalia/colors.json`.

They're tracked so a fresh install starts fully themed (`hyprland.lua` `require`s `noctalia.lua`). Expect them to show up in `git status` when you change wallpaper/scheme — commit them or `git checkout` them, your call. If noctalia replaces one of the symlinks with a regular file, see "doesn't stick" above.

Plugin **code** in `~/.config/noctalia/plugins/` is not tracked (noctalia re-downloads it from the registry listed in `plugins.json`); only each plugin's `settings.json` is.

---

## Secrets

**Never put tokens, passwords or API keys in a tracked file. This repo is public.**

- Shell secrets go in `~/.zshrc.local` — sourced by `.zshrc`, ignored by git, `chmod 600`.
- A **gitleaks** pre-commit hook (`hooks/pre-commit`, enabled via `git config core.hooksPath hooks`) scans every commit and blocks it if anything looks like a secret.
  - If it flags a false positive, add a `# gitleaks:allow` comment on that line.
  - If you *did* commit a real secret: rotate it first (assume it's leaked), then clean history.

---

## Package lists

`pkglist/native.txt` and `pkglist/aur.txt` list explicitly-installed packages. A pacman hook (`/etc/pacman.d/hooks/dotfiles-pkglist.hook`, installed by `bootstrap.sh` from `system/pkglist.hook.in`) regenerates them after every install/remove — you just commit the diff when you see it. Regenerate manually with `pkglist/update.sh`.

Not covered by the lists (install by hand if needed): Homebrew (`/home/linuxbrew`), nvm (`~/.config/nvm`), rustup, sdkman.

---

## Wallpapers (Git LFS)

Images under `wallpapers/` are stored with [Git LFS](https://git-lfs.com/) (`.gitattributes`), so the git history only holds small pointer files. `git lfs install` is done by `bootstrap.sh`; after that `git add`/`commit`/`push` work as usual. If you see tiny text files instead of images, run `git lfs pull`.
