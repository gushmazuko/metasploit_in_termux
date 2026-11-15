#!/data/data/com.termux/files/usr/bin/bash
#
# Metasploit Framework installer for Termux
# https://github.com/gushmazuko/metasploit_in_termux
#
# Commands:
#   bash <(curl -fsSL .../metasploit.sh)               install (default)
#   bash <(curl -fsSL .../metasploit.sh) --with-db     install + optional postgres DB
#   msf-setup --update                                 update Metasploit in place
#   msf-setup --uninstall [--purge]                    uninstall
#
# After install the script saves a copy of itself and links it as
# `msf-setup`, so the commands above are also available offline.
#
# Compatibility notes (verified on CI, Nov 2026 — Termux ruby 4.0.9 / clang 21.1.8):
# - nokogiri builds cleanly from source with system libxml2/libxslt
# - bundler must run with `version system`: the lockfile's BUNDLED WITH (2.5.22)
#   predates Ruby 4.0 default-gem handling, and bundler's auto-switch on it
#   clobbers the `bundle` binstub shebang on Termux
# - msf binaries ship `#!/usr/bin/env ruby` shebangs and Android has no
#   /usr/bin/env: termux-fix-shebang on them is mandatory
# - Ruby 4.0 ships date 3.5.1 as a default gem; MSF pins date '3.4.1' exactly
#   in its gemspec, so the pin is relaxed locally and the lockfile aligned

# If sourced from a real file, re-execute as a script so strict mode cannot
# kill the interactive shell. Piping into `source` cannot work: bash drains
# the pipe while parsing, so re-exec would run an empty script — refuse it.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  if [[ -f "${BASH_SOURCE[0]}" ]]; then
    ( exec bash "${BASH_SOURCE[0]}" "$@" )
    return
  fi
  echo "Piping into 'source' is not supported. Use:" >&2
  echo "  bash <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)" >&2
  return 1
fi

set -Eeuo pipefail
trap 'echo -e "\n\033[31m[!] Operation failed near line $LINENO — see the error above.\033[0m" >&2' ERR
trap 'termux-wake-unlock 2>/dev/null || true' EXIT

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
MSF_DIR="${PREFIX}/opt/metasploit-framework"
INSTALLER_DIR="${PREFIX}/opt/msf-termux-installer"
SCRIPT_URL="https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh"

die() { echo -e "\033[31m[!] $*\033[0m" >&2; exit 1; }

center_banner() {
    local termwidth
    termwidth="$(tput cols 2>/dev/null || echo 80)"
    local banner=(
        "+-+-+-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+"
        "|M|e|t|a|s|p|l|o|i|t| |i|n| |T|e|r|m|u|x|"
        "+-+-+-+-+-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+"
        "+-+-+ +-+-+-+-+-+-+-+-+-+-+"
        "|b|y| |G|u|s|h|m|a|z|u|k|o|"
        "+-+-+ +-+-+-+-+-+-+-+-+-+-+"
    )
    echo -e "\e[34m"
    for line in "${banner[@]}"; do
        printf "%*s\n" $(( (termwidth + ${#line}) / 2 )) "$line"
    done
    echo -e "\e[0m"
}

center() {
  local termwidth padding
  termwidth="$(tput cols 2>/dev/null || echo 80)"
  padding="$(printf '%0.1s' ={1..500})"
  printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

usage() {
  cat <<'EOF'
Metasploit Framework installer for Termux

Usage:
  metasploit.sh [options]

Options:
                  install Metasploit (default action)
  --with-db       also initialize an optional postgres database (~/.msf4/db,
                  port 5433, msf database) — never touches an existing one
  --update        update an existing installation in place
  --uninstall     remove Metasploit, its symlinks and this installer
  --purge         with --uninstall: also delete ~/.msf4 (loot, history, db!)
  --no-banner     skip the banner
  -h, --help      this help

After install, `msf-setup` is available as a command for --update/--uninstall.
EOF
}

PKG_LIST=(binutils python autoconf bison clang coreutils curl findutils apr
  apr-util postgresql openssl readline libffi libgmp libpcap libsqlite libgrpc
  libtool libxml2 libxslt ncurses make ncurses-utils ncurses git wget unzip
  zip tar termux-tools termux-elf-cleaner pkg-config ruby)
NOKOGIRI_CFLAGS="-Wno-implicit-function-declaration -Wno-deprecated-declarations -Wno-incompatible-function-pointer-types"

# Save a copy of this script so `msf-setup` works offline later. When run as
# a file, copy it. When piped (`bash <(curl ...)`), ${BASH_SOURCE} is a pipe
# that bash has already drained by the time we execute — copying it yields a
# truncated file (verified) — so fetch a fresh copy from the canonical URL
# and validate it instead.
self_install() {
  mkdir -p "$INSTALLER_DIR"
  local src="${BASH_SOURCE[0]}" tmp
  if [[ -f "$src" ]]; then
    if ! cmp -s "$src" "${INSTALLER_DIR}/metasploit.sh"; then
      cp "$src" "${INSTALLER_DIR}/metasploit.sh"
    fi
  else
    tmp="$(mktemp)"
    curl -fsSL "$SCRIPT_URL" -o "$tmp"
    [ -s "$tmp" ] || die "could not download the installer for msf-setup"
    bash -n "$tmp" || die "downloaded installer failed syntax check"
    cp "$tmp" "${INSTALLER_DIR}/metasploit.sh"
    rm -f "$tmp"
  fi
  chmod +x "${INSTALLER_DIR}/metasploit.sh"
  [ -s "${INSTALLER_DIR}/metasploit.sh" ] || die "msf-setup copy is empty"
  ln -sf "${INSTALLER_DIR}/metasploit.sh" "${PREFIX}/bin/msf-setup"
}

step_deps() {
  center "* Dependencies installation..."
  # Skip mirror selection if sources.list is already configured (for CI)
  if ! grep -q "packages.termux.dev" "${PREFIX}/etc/apt/sources.list" 2>/dev/null; then
    pkg update -y
  else
    apt update -y
  fi
  DEBIAN_FRONTEND=noninteractive pkg upgrade -y -o Dpkg::Options::="--force-confnew"
  DEBIAN_FRONTEND=noninteractive pkg install -y "${PKG_LIST[@]}" -o Dpkg::Options::="--force-confnew"
}

step_fetch() {
  center "* Erasing old metasploit folder & downloading..."
  rm -rf "$MSF_DIR"
  mkdir -p "${PREFIX}/opt"
  git clone https://github.com/rapid7/metasploit-framework.git --depth=1 "$MSF_DIR"
}

# For updates: hard-reset to upstream master. A plain `git pull` would fail —
# this installer intentionally modifies tracked files (gemspec pin, lockfile
# alignment) and upstream moves Gemfile.lock weekly. Vendor gems and .bundle
# are untracked, so they survive the reset.
step_reset_to_master() {
  center "* Updating metasploit..."
  cd "$MSF_DIR"
  git fetch --depth=1 origin master
  git reset --hard FETCH_HEAD
}

# Ruby 4.0 ships newer default gems than MSF's lockfile pins. RubyGems
# activates the default `date` while loading gem specifications, before
# msfconsole's bundler/setup runs, so a lockfile pinned to an older date
# fails with "You have already activated date 3.5.1..." — under every
# bundler version. Align the lockfile with the shipped default.
align_default_gem() {
  local name="$1" default_version locked_version
  case "$name" in
    date)     default_version="$(ruby -e 'require "date"; puts Date::VERSION' 2>/dev/null || true)" ;;
    stringio) default_version="$(ruby -e 'require "stringio"; puts StringIO::VERSION' 2>/dev/null || true)" ;;
    *) default_version="" ;;
  esac
  # Accept only plain numeric dotted versions — a failed probe must never
  # write garbage into the lockfile.
  case "$default_version" in ''|*[!0-9.]*) default_version="" ;; esac
  locked_version="$(sed -n "s/^    ${name} (\(.*\))\$/\1/p" Gemfile.lock | head -n1)"
  echo "default-gem check: ${name} default=${default_version:-unknown} locked=${locked_version:-absent}"
  if [ -n "$default_version" ] && [ -n "$locked_version" ] && [ "$default_version" != "$locked_version" ]; then
    echo "Aligning lockfile ${name} ${locked_version} -> ${default_version}"
    sed -i "s/^    ${name} (${locked_version})/    ${name} (${default_version})/" Gemfile.lock
  fi
}

# MSF's gemspec pins date exactly ('3.4.1' — "Temporarily pinned until 3.5
# can be tested"), which forces bundler to revert the lockfile alignment
# ("Fetching date 3.4.1 (was 3.5.1)", verified on CI). Relax the pin so the
# Ruby-4.0 default (3.5.1) can satisfy it. Fail loudly if the line changed
# shape upstream and the relax did not apply — a silent no-op here means a
# broken msfconsole at runtime.
relax_date_pin() {
  if grep -q "add_runtime_dependency 'date', '" metasploit-framework.gemspec; then
    sed -i "s/\(add_runtime_dependency 'date', '\)[0-9][^']*/\1>= 3.4.1/" metasploit-framework.gemspec
    if grep -q "add_runtime_dependency 'date', '[0-9]" metasploit-framework.gemspec; then
      die "date pin in metasploit-framework.gemspec was not recognized and could not be relaxed — upstream changed it; please open an issue"
    fi
    echo "Relaxed date pin in metasploit-framework.gemspec"
  else
    echo "NOTE: date pin not found in gemspec (upstream may have relaxed it already)"
  fi
}

# Everything that has to be (re-)done after the framework source is at the
# wanted revision: shared by install and update.
step_sync_gems() {
  center "* Installation..."
  cd "$MSF_DIR"
  align_default_gem date
  align_default_gem stringio
  relax_date_pin

  gem install bundler -v '~> 4.0.0'
  bundle config set --local version system
  # Isolate all bundle gems inside the framework dir: `msf-setup --uninstall`
  # then removes everything with `rm -rf` and nothing leaks into the Ruby
  # install shared with the user's other tools.
  bundle config set --local path vendor/bundle
  bundle config set --local build.nokogiri "--use-system-libraries --with-cflags=${NOKOGIRI_CFLAGS}"
  # Without this, sqlite3's extconf tries to compile its packaged sqlite and
  # requires mini_portile2 (not installed), failing with LoadError.
  bundle config set --local build.sqlite3 "--enable-system-libraries"
  termux-fix-shebang "${PREFIX}/bin/bundle" "${PREFIX}/bin/bundler" 2>/dev/null || true

  bundle install -j"$(nproc --all)"
}

step_fixups() {
  center "* Fixing shebangs and linking executables..."
  cd "$MSF_DIR"
  termux-fix-shebang msfconsole msfvenom msfrpcd
  ln -sf "${MSF_DIR}/msfconsole" "${PREFIX}/bin/"
  ln -sf "${MSF_DIR}/msfvenom" "${PREFIX}/bin/"
  ln -sf "${MSF_DIR}/msfrpcd" "${PREFIX}/bin/"
  termux-elf-cleaner "${MSF_DIR}"/vendor/bundle/*/gems/pg-*/lib/pg_ext.so 2>/dev/null || true
}

# The whole "install is green but msfconsole is broken at runtime" failure
# class (default-gem conflicts, bundler version drift, broken shebangs)
# surfaces here instead of on the user's first launch.
boot_probe() {
  center "* Verifying msfconsole boots..."
  (cd "$MSF_DIR" && ./msfconsole -qx "version; exit" >/dev/null) \
    || die "msfconsole failed to boot — see errors above; the install is incomplete"
}

# Optional postgres for msf: dedicated datadir and port, msfdb-style, so a
# user's existing Termux postgres cluster is never touched. Idempotent.
step_db() {
  center "* Initializing optional database..."
  local datadir="${HOME}/.msf4/db"
  mkdir -p "$HOME/.msf4"
  if [ ! -f "${datadir}/PG_VERSION" ]; then
    initdb "$datadir"
  fi
  if ! pg_ctl -D "$datadir" status >/dev/null 2>&1; then
    pg_ctl -D "$datadir" -o "-p 5433" -l "${datadir}/pg.log" start
    sleep 2
  fi
  if ! createdb -p 5433 msf_database >/dev/null 2>&1; then
    psql -p 5433 -tAc "SELECT 1 FROM pg_database WHERE datname='msf_database'" postgres 2>/dev/null | grep -q 1 \
      || die "could not create the msf_database database"
  fi
  if [ -f "${HOME}/.msf4/database.yml" ]; then
    echo "Keeping existing ${HOME}/.msf4/database.yml"
  else
  cat > "${HOME}/.msf4/database.yml" <<EOF
production:
  adapter: postgresql
  database: msf_database
  username: $(whoami)
  host: 127.0.0.1
  port: 5433
  pool: 5
  timeout: 5
EOF
  fi
  echo "Database configured in ${HOME}/.msf4/database.yml"
  echo "Note: after a reboot, restart it with: pg_ctl -D ~/.msf4/db -o '-p 5433' start"
}

cmd_install() {
  clear
  [ "${NO_BANNER:-0}" -eq 0 ] && center_banner || true
  termux-wake-lock 2>/dev/null || true
  self_install
  step_deps
  step_fetch
  step_sync_gems
  step_fixups
  if [ "$WITH_DB" -eq 1 ]; then step_db; fi
  boot_probe
  echo -e "\033[32m"
  center "Installation complete"
  echo -e "\nStart Metasploit using the command: msfconsole"
  echo -e "Update with: msf-setup --update   |  Remove with: msf-setup --uninstall"
  echo -e "\033[0m"
}

cmd_update() {
  clear
  [ "${NO_BANNER:-0}" -eq 0 ] && center_banner || true
  termux-wake-lock 2>/dev/null || true
  self_install
  [ -d "$MSF_DIR" ] || die "Metasploit is not installed at ${MSF_DIR}. Run the installer without --update first."
  step_reset_to_master
  step_sync_gems
  step_fixups
  boot_probe
  echo -e "\033[32m"
  center "Update complete"
  echo -e "\nStart Metasploit using the command: msfconsole"
  echo -e "\033[0m"
}

cmd_uninstall() {
  clear
  [ "${NO_BANNER:-0}" -eq 0 ] && center_banner || true
  center "* Uninstalling..."
  # Stop our postgres (if --with-db was used) so no orphaned server keeps
  # holding port 5433 after the data below is deleted.
  if [ -f "${HOME}/.msf4/db/PG_VERSION" ]; then
    pg_ctl -D "${HOME}/.msf4/db" stop -m fast >/dev/null 2>&1 || true
  fi
  # Remove msf symlinks only if they actually point into our framework dir —
  # other installers create the same names.
  local b target
  for b in msfconsole msfvenom msfrpcd; do
    if [ -L "${PREFIX}/bin/${b}" ]; then
      target="$(readlink -f "${PREFIX}/bin/${b}" 2>/dev/null || true)"
      if [[ "$target" == "$MSF_DIR" || "$target" == "$MSF_DIR/"* ]]; then
        rm -f "${PREFIX}/bin/${b}"
      else
        echo "keeping ${PREFIX}/bin/${b} (points to ${target:-nowhere})"
      fi
    fi
  done
  rm -rf "$MSF_DIR"
  rm -f "${PREFIX}/bin/msf-setup"
  rm -rf "$INSTALLER_DIR"
  if [ "$PURGE" -eq 1 ]; then
    echo -e "\033[31m--purge: deleting ${HOME}/.msf4 (loot, history, database)\033[0m"
    rm -rf "${HOME}/.msf4"
  else
    echo "Kept ${HOME}/.msf4 (loot, history, settings). Use --purge to delete it too."
  fi
  echo -e "\033[32m"
  center "Uninstall complete"
  echo -e "\033[0m"
}

ACTION="install"
WITH_DB=0
PURGE=0
NO_BANNER=0
while [ $# -gt 0 ]; do
  case "$1" in
    --update)    ACTION="update" ;;
    --uninstall) ACTION="uninstall" ;;
    --with-db)   WITH_DB=1 ;;
    --purge)     PURGE=1 ;;
    --no-banner) NO_BANNER=1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done
[ "$PURGE" -eq 1 ] && [ "$ACTION" != "uninstall" ] && die "--purge only makes sense with --uninstall"

case "$ACTION" in
  install)   cmd_install ;;
  update)    cmd_update ;;
  uninstall) cmd_uninstall ;;
esac
