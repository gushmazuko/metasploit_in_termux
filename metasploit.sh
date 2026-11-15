#!/data/data/com.termux/files/usr/bin/bash
#
# Metasploit Framework installer for Termux
# https://github.com/gushmazuko/metasploit_in_termux
#
# Compatibility notes (verified on CI, Nov 2026 — Termux ruby 4.0.9 / clang 21.1.8):
# - nokogiri builds cleanly from source with system libxml2/libxslt
# - bundler MUST be invoked pinned to Gemfile.lock's "BUNDLED WITH" version:
#   bundler 4.x auto-installs the locked version on first `bundle install` and
#   re-execs itself, which clobbers the `bundle` binstub shebang on Termux
# - msfconsole/msfvenom/msfrpcd ship `#!/usr/bin/env ruby` shebangs and Android
#   has no /usr/bin/env: termux-fix-shebang on them is mandatory

# Legacy safety: if someone sources this script (old README one-liner),
# re-execute it as a real script so strict mode cannot kill their shell.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  ( exec bash "${BASH_SOURCE[0]}" "$@" )
  return
fi

set -Eeuo pipefail
trap 'echo -e "\n\033[31m[!] Installation failed near line $LINENO — see the error above.\033[0m" >&2' ERR

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

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

    echo -e "\e[34m" # Blue color
    for line in "${banner[@]}"; do
        printf "%*s\n" $(( (termwidth + ${#line}) / 2 )) "$line"
    done
    echo -e "\e[0m" # Reset color
}

center() {
  local termwidth
  termwidth="$(tput cols 2>/dev/null || echo 80)"
  local padding
  padding="$(printf '%0.1s' ={1..500})"
  printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

clear
center_banner

# Dependencies Installation
center "* Dependencies installation..."
# Skip mirror selection if sources.list is already configured (for CI)
if ! grep -q "packages.termux.dev" "${PREFIX}/etc/apt/sources.list" 2>/dev/null; then
  pkg update -y
else
  apt update -y
fi
DEBIAN_FRONTEND=noninteractive pkg upgrade -y -o Dpkg::Options::="--force-confnew"
DEBIAN_FRONTEND=noninteractive pkg install -y binutils python autoconf bison clang coreutils curl findutils apr apr-util postgresql openssl readline libffi libgmp libpcap libsqlite libgrpc libtool libxml2 libxslt ncurses make ncurses-utils ncurses git wget unzip zip tar termux-tools termux-elf-cleaner pkg-config ruby -o Dpkg::Options::="--force-confnew"

# Erase Old Metasploit Folder
center "* Erasing old metasploit folder..."
rm -rf "${PREFIX}/opt/metasploit-framework"

# Download Metasploit
center "* Downloading..."
mkdir -p "${PREFIX}/opt"
git clone https://github.com/rapid7/metasploit-framework.git --depth=1 "${PREFIX}/opt/metasploit-framework"

# Install Metasploit
center "* Installation..."
cd "${PREFIX}/opt/metasploit-framework"

# Ruby 4.0 ships newer default gems than MSF's lockfile pins. RubyGems
# activates the default `date` while loading gem specifications, before
# msfconsole's bundler/setup runs, so a lockfile pinned to an older date
# fails with "You have already activated date 3.5.1, but your Gemfile
# requires date 3.4.1" — under every bundler version. Align the lockfile
# with the shipped default; when both sides match, no bundler can conflict.
# Extend the list if another default gem conflicts the same way.
align_default_gem() {
  local name="$1" default_version locked_version
  case "$name" in
    date) default_version="$(ruby -e 'require "date"; puts Date::VERSION' 2>/dev/null || true)" ;;
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
align_default_gem date

# Run everything under the bundler shipped with Ruby 4.0, not the lockfile's
# BUNDLED WITH (2.5.22): that version predates Ruby 4.0 default-gem handling
# and msfconsole dies with "You have already activated date 3.5.1, but your
# Gemfile requires date 3.4.1" (verified on CI). `version system` also stops
# bundler from auto-installing the locked version mid-install and re-exec'ing
# itself, which breaks the `bundle` binstub shebang on Termux.
gem install bundler
bundle config set --local version system
termux-fix-shebang "${PREFIX}/bin/bundle" "${PREFIX}/bin/bundler" 2>/dev/null || true

# Native gem build flags, registered where bundler will use them.
# nokogiri: system libxml2/libxslt + clang warning suppressions.
bundle config set --local build.nokogiri \
  "--use-system-libraries --with-cflags=-Wno-implicit-function-declaration -Wno-deprecated-declarations -Wno-incompatible-function-pointer-types"
# sqlite3: use Termux's libsqlite. Without this, the gem's extconf tries to
# compile its packaged sqlite and requires mini_portile2 (not installed),
# failing with LoadError (verified on CI, Nov 2026).
bundle config set --local build.sqlite3 "--enable-system-libraries"

# Pre-build nokogiri pinned to the lockfile version (same flags). Plain ERE
# parsing — grep -P is not guaranteed on all Termux builds.
NOKOGIRI_VERSION="$(grep -i '^    nokogiri (' Gemfile.lock | sed 's/[()]//g' | awk '{print $2}' | cut -d- -f1 | head -n1 || true)"
if [ -n "$NOKOGIRI_VERSION" ]; then
  gem install nokogiri -v "$NOKOGIRI_VERSION" -- --use-system-libraries --with-cflags="-Wno-implicit-function-declaration -Wno-deprecated-declarations -Wno-incompatible-function-pointer-types"
fi

# Single, deterministic install.
bundle install -j"$(nproc --all)"

# Fix shebangs (#!/usr/bin/env ruby does not work on Android) and link
# Metasploit executables
center "* Fixing shebangs and linking executables..."
termux-fix-shebang msfconsole msfvenom msfrpcd
ln -sf "${PREFIX}/opt/metasploit-framework/msfconsole" "${PREFIX}/bin/"
ln -sf "${PREFIX}/opt/metasploit-framework/msfvenom" "${PREFIX}/bin/"
ln -sf "${PREFIX}/opt/metasploit-framework/msfrpcd" "${PREFIX}/bin/"
termux-elf-cleaner "${PREFIX}"/lib/ruby/gems/*/gems/pg-*/lib/pg_ext.so 2>/dev/null || true

echo -e "\033[32m" # Green color
center "Installation complete"
echo -e "\nStart Metasploit using the command: msfconsole"
echo -e "\033[0m" # Reset color
