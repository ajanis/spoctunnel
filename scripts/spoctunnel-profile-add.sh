#!/bin/sh

NL='
'

zshProfile=$(cat ~/.zshrc | sed '/spoctunnel/d')
echo "${zshProfile}${NL}${NL}# Leave this spoctunnel.zsh incantation as a single line, so that homebrew upgrades are smooth${NL}if [ -f $(brew --prefix)/etc/spoctunnel/spoctunnel.zsh ]; then source $(brew --prefix)/etc/spoctunnel/spoctunnel.zsh; fi${NL}" > ~/.zshrc

echo "*** Did the above fail with permissions errors? ***"
echo "If yes, you will need to do this after homebrew finishes (once off):"
echo "  /usr/local/Cellar/spoctunnel/$1/bin/spoctunnel-profile-add.sh"