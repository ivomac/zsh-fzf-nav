#!/usr/bin/env zsh

repos=()
while read -r repo_path; do
  repos+=("$repo_path")
done

for repo_path in "${repos[@]}"; do
  "${0:A:h}/repostatus.zsh" "$@" "${repo_path}" &
done

wait
