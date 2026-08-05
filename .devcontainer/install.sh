#!/usr/bin/env bash
#
# Post installation script for an ECI Container
#
# 1. Install dotfiles from Company repository
cd "$HOME" || exit
git clone https://github.com/ec-intl/dotfiles.git
cd dotfiles || exit
./install bash
cd "$HOME" || exit

# 2. Copy custom bash dotfiles
cp -r /tmp/bash-src /home/"${USER}"/
