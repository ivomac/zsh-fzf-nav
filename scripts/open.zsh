#!/usr/bin/env zsh

open="$1"
target="${2:A}"
shift 2

if [[ -d "$target" ]]; then
  cwd="$target"
else
  cwd="${target:h}"
fi

exec zsh -ic 'builtin cd -- "$1" || exit; shift; exec "$@"' zsh \
  "$cwd" "$open" "$target" "$@"
