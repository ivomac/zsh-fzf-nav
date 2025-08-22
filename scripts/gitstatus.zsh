#!/usr/bin/env zsh

while read -r repo_path; do
  "${0:A:h}/repostatus.zsh" "$@" "${repo_path}"
done
