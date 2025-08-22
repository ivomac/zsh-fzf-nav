#!/usr/bin/env zsh

autoload -U colors && colors
RED=$fg[red]
GREEN=$fg[green]
YELLOW=$fg[yellow]
BLUE=$fg[blue]
RESET=$reset_color

fetch_remote=false
if [[ "$1" == "-f" ]]; then
    fetch_remote=true
    shift
fi

separator="$1"

repo_path="$2"

# Change to repo directory
builtin cd "${repo_path}" 2>/dev/null || exit 0

# update remote info
if $fetch_remote; then
  git remote update >/dev/null 2>&1
fi

issues=()

# Check for uncommitted changes (staged, unstaged, untracked)
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  change_details=()
  (( staged > 0 )) && issues+=("${RED}${staged} staged${RESET}")
  (( unstaged > 0 )) && issues+=("${RED}${unstaged} modified${RESET}")
  (( untracked > 0 )) && issues+=("${RED}${untracked} untracked${RESET}")
fi

# Check for stashes
stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
if (( stash_count > 0 )); then
  ext="es"
  if (( stash_count == 1 )); then
    ext=""
  fi
  issues+=("${YELLOW}${stash_count} stash$ext${RESET}")
fi

# Check remote status
if git rev-parse --verify @{u} >/dev/null 2>&1; then
  # Check if behind remote
  behind_count=$(git rev-list --count ..@{u} 2>/dev/null || echo 0)
  if (( behind_count > 0 )); then
    issues+=("${BLUE}${behind_count} behind${RESET}")
  fi

  # Check if ahead of remote
  ahead_count=$(git rev-list --count @{u}.. 2>/dev/null || echo 0)
  if (( ahead_count > 0 )); then
    issues+=("${GREEN}${ahead_count} ahead${RESET}")
  fi
else
  # No upstream branch set, but has commits
  if [[ -n "$(git log --oneline -1 2>/dev/null)" ]]; then
    issues+=("${YELLOW}no upstream${RESET}")
  fi
fi

# Print repo and issues if any found
if (( ${#issues} > 0 )); then
  printf "%s${separator}%s\n" "$repo_path" "${(j: | :)issues}"
fi
