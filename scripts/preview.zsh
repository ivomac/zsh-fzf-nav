#!/usr/bin/env zsh

file=$1
line=$2

flags=""
if [[ -L "$file" ]]; then
  echo "Symlink -> $(readlink -f "$file")\n"
  flags+="--links"
fi

ftype=$(file -b --mime "$file")

if [[ -d "$file" ]]; then
  eza -Al --color=always $flags "$file"
elif [[ -f "$file" ]]; then
  if [[ "$ftype" == text/* ]]; then
    if [[ $line =~ ^[0-9]+$ ]]; then
      start=$(($line - 10))
      if [[ $start -le 0 ]]; then
        start=1
      fi
      bat --line-range="$start:" --highlight-line "$line" "$file"
    else
      bat "$file"
    fi
  else
    echo "Binary file"
  fi
elif [[ -n "$file" ]]; then
  bat "$file"
fi
