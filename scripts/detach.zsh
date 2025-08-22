#!/usr/bin/env zsh

term="$1"
open="$2"
file=$(printf "%q" $3)

"$term" -e zsh -ic "$open $file $4" &>/dev/null & disown
