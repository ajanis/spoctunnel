#!/bin/bash
echo << EOF >> ~/.zshrc
# Add additional includes
[[ -f ~/.spoc.zsh ]] && source ~/.spoc.zsh
EOF