#!/usr/bin/env bash
#
# Post installation script for an ECI Container
#
set -euo pipefail

# 1. Install dotfiles from Company repository
cd "$HOME" || exit

if [ ! -d dotfiles ]; then
    git clone https://github.com/ec-intl/dotfiles.git
fi

cd dotfiles || exit
if ! git pull --ff-only; then
    echo "Warning: failed to fast-forward dotfiles repository; continuing with existing checkout." >&2
fi
./install bash
cd "$HOME" || exit

# 2. Copy custom bash dotfiles
mkdir -p "$HOME"/bash-src
cp -r /tmp/bash-src/. "$HOME"/bash-src/
