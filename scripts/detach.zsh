#!/usr/bin/env zsh

term="$1"
runner="$2"
open="$3"
file="$4"

"$term" -e "$runner" "$open" "$file" "$5" &>/dev/null & disown
