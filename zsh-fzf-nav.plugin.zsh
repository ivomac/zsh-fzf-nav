export _FZF_NAV_SCRIPTS="${0:A:h}/scripts"

function _fzf-nav {

  _FZF_NAV_BECOME_TMP="/tmp/zsh-fzf-nav.$$.out"

  _FZF_NAV_PREVIEW="${FZF_NAV_PREVIEW:-${_FZF_NAV_SCRIPTS}/preview.zsh}"

  _FZF_NAV_SEPARATOR=${FZF_NAV_SEPARATOR:-◇}

  _FZF_NAV_MODE_FIND="
  label='ERR'
  if [[ \$FZF_INPUT_LABEL =~ Search ]]; then
    flag='--type=directory'
    label='󰥨 Directories'
  elif [[ \$FZF_INPUT_LABEL =~ Directories ]]; then
    flag='--type=file'
    label='󰱼 Files'
  else
    flag='--type=file --type=directory --type=block-device --type=char-device --type=socket --type=pipe'
    label='󱈇 Search'
  fi

  echo \"change-input-label( \$label )+reload:fd ${FZF_NAV_FD_OPTS[*]} \$flag\"
  "

  _FZF_NAV_GITDIRS="fd ${FZF_NAV_FD_OPTS[*]} --type=dir '^\.git$' '.' --exec echo '{//}'"

  _FZF_NAV_MODE_GIT="
    label='ERR'
    if [[ \$FZF_INPUT_LABEL =~ Git ]]; then
      cmd=\"${_FZF_NAV_GITDIRS} | '$_FZF_NAV_SCRIPTS/gitstatus.zsh' '$_FZF_NAV_SEPARATOR'\"
      label='󱝩 Status'
    elif [[ \$FZF_INPUT_LABEL =~ Status ]]; then
      cmd=\"${_FZF_NAV_GITDIRS} | '$_FZF_NAV_SCRIPTS/gitstatus.zsh' -f '$_FZF_NAV_SEPARATOR'\"
      label='󱝩 Fetch'
    else
      cmd=\"$_FZF_NAV_GITDIRS\"
      label='󱝩 Git'
    fi
    echo \"change-input-label( \$label )+reload:\$cmd\"
  "

  fzf \
    --ansi \
    --scheme=path \
    --delimiter="$_FZF_NAV_SEPARATOR" \
    --header="\
↵:Exit+CD+Open ^O:Open ^D:Detach ^U:User | ^F:Find ^R:Grep ^G:Git ^T:User" \
    --preview="$_FZF_NAV_PREVIEW {1} {2}" \
    --bind="focus:transform:echo \"change-preview-label( \$(basename {1}) )\"" \
    --bind="ctrl-f,start:transform:$_FZF_NAV_MODE_FIND" \
    --bind="ctrl-r:change-input-label( 󱎸 Grep )+reload:rg ${FZF_NAV_RG_OPTS[*]} --field-match-separator=${_FZF_NAV_SEPARATOR} {q}" \
    --bind="ctrl-g:transform:$_FZF_NAV_MODE_GIT" \
    --bind="ctrl-t:change-input-label( 󰺄 User )+reload:$FZF_NAV_USER_MODE" \
    --bind="ctrl-o:execute:$FZF_NAV_OPEN {1}" \
    --bind="ctrl-d:execute:$_FZF_NAV_SCRIPTS/detach.zsh $FZF_NAV_TERMCMD $FZF_NAV_OPEN {1}" \
    --bind="ctrl-u:execute:$FZF_NAV_USER_OPEN {1} {2}" \
    --bind="enter:become:$_FZF_NAV_SCRIPTS/become.zsh {1} {2} \"$_FZF_NAV_BECOME_TMP\""

  if [[ -f "$_FZF_NAV_BECOME_TMP" ]]; then
    {
      IFS= read -r file
      IFS= read -r line
    } <"$_FZF_NAV_BECOME_TMP"
    rm "$_FZF_NAV_BECOME_TMP"
    if [[ -f "$file" ]] || [[ -d "$file" ]]; then
      file=$(realpath --strip "$file")
      if [[ -d "$file" ]]; then
        builtin cd "$file"
      else
        builtin cd "$(dirname "$file")"
      fi
      file=$(printf %q "$file")
      BUFFER="$FZF_NAV_OPEN $file $line"
      zle accept-line
    fi
  fi

}
zle -N _fzf-nav
