#!/usr/bin/env bash
#
# Installer for the Linux Desktop App Template reference application.
#
#   ./install.sh              install and register the application
#   ./install.sh --desktop    additionally place an icon on the desktop
#   ./install.sh --uninstall  remove everything this script installs
#
# Environment variables:
#   SCRIPTS_DIR   destination for the script (default: ~/scripts)

set -euo pipefail

APP="app-custom-example"
NAME="App Custom Example"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/scripts}"
APPS_DIR="$HOME/.local/share/applications"

# The desktop directory name is localised. xdg-user-dir is the only reliable
# way to resolve it.
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
info() { printf '  \033[34m→\033[0m %s\n' "$1"; }
die()  { printf '  \033[31m✗\033[0m %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------------
uninstall() {
  echo "Uninstalling $NAME..."
  rm -f "$SCRIPTS_DIR/$APP.sh" "$APPS_DIR/$APP.desktop" "$DESKTOP_DIR/$APP.desktop"
  command -v update-desktop-database >/dev/null && update-desktop-database "$APPS_DIR" 2>/dev/null || true

  # A pinned entry whose .desktop no longer exists leaves a broken dock icon.
  if command -v gsettings >/dev/null && gsettings get org.gnome.shell favorite-apps 2>/dev/null | grep -q "$APP.desktop"; then
    local favs
    favs=$(gsettings get org.gnome.shell favorite-apps | sed "s/'$APP.desktop', //; s/, '$APP.desktop'//; s/'$APP.desktop'//")
    gsettings set org.gnome.shell favorite-apps "$favs"
    ok "removed from dock favourites"
  fi
  ok "uninstalled"
  exit 0
}

# ---------------------------------------------------------------------
WITH_DESKTOP_ICON=false
for arg in "${@:-}"; do
  case "$arg" in
    --uninstall) uninstall ;;
    --desktop)   WITH_DESKTOP_ICON=true ;;
    "")          ;;
    *)           die "unknown option: $arg" ;;
  esac
done

echo "Installing $NAME..."

# 1. Dependencies. zenity is required; notify-send is not.
command -v zenity >/dev/null || die "zenity not found. Install it with: sudo apt install zenity"
ok "zenity $(zenity --version 2>/dev/null || echo '?') found"
command -v notify-send >/dev/null || info "notify-send not found: capability 3 will be skipped (sudo apt install libnotify-bin)"

# 2. Install the script.
mkdir -p "$SCRIPTS_DIR"
install -m 755 "$REPO_DIR/src/$APP.sh" "$SCRIPTS_DIR/$APP.sh"
ok "script installed to $SCRIPTS_DIR"

# 3. Generate the .desktop entry. Exec= performs no shell expansion, so the
#    absolute path must be substituted here rather than committed.
mkdir -p "$APPS_DIR"
sed "s|__EXEC_PATH__|$SCRIPTS_DIR/$APP.sh|" \
    "$REPO_DIR/src/$APP.desktop.template" > "$APPS_DIR/$APP.desktop"
chmod +x "$APPS_DIR/$APP.desktop"

if command -v desktop-file-validate >/dev/null; then
  desktop-file-validate "$APPS_DIR/$APP.desktop" || die "generated .desktop entry failed validation"
  ok ".desktop entry generated and validated"
else
  ok ".desktop entry generated"
fi

# 4. Register it. Without this the application does not appear in the
#    activities overview and cannot be pinned.
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS_DIR" 2>/dev/null || true
ok "registered with the system"

# 5. Optional standalone desktop icon.
if $WITH_DESKTOP_ICON; then
  if [ -d "$DESKTOP_DIR" ]; then
    cp "$APPS_DIR/$APP.desktop" "$DESKTOP_DIR/$APP.desktop"
    chmod +x "$DESKTOP_DIR/$APP.desktop"
    command -v gio >/dev/null && gio set "$DESKTOP_DIR/$APP.desktop" metadata::trusted true 2>/dev/null || true
    ok "desktop icon placed in $DESKTOP_DIR"
    info "GNOME may require 'Allow Launching' from the context menu on first use"
  else
    info "desktop directory not found, skipped"
  fi
fi

echo
echo "Done. Open the activities overview and search for: $NAME"
echo "To pin it: right-click the icon and select Add to Favourites."
echo "Documentation: $REPO_DIR/docs/guide.md"
