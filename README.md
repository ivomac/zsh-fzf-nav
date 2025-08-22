# FZF Nav Plugin

A zsh plugin that defines an interactive file/directory navigator using fzf. Offers multiple navigation modes, git integration, and customizable actions.

## Features

- **Multiple Navigation Modes**:
  - File and directory browsing with toggling between types
  - Text search within files using ripgrep
  - Git repository management with status checking
  - Bookmark integration with yazi file manager

- **Rich Git Integration**:
  - List git repositories
  - Show repository status with modified files count
  - Git fetch operations across multiple repos
  - Launch lazygit for detailed git operations

- **Flexible Actions**:
  - Navigate to directories (with or without opening files)
  - Open files in your configured editor
  - Launch files in detached terminal sessions
  - Preview files with syntax highlighting
  - Copy selections to clipboard

## Installation

### Prerequisites

- **Needed**:
  * [fzf](https://github.com/junegunn/fzf) - fuzzy finder
  * [fd](https://github.com/sharkdp/fd) - faster find
  * [ripgrep](https://github.com/BurntSushi/ripgrep) - faster grep
- **Recommended**:
  * Nerd-fonts compatible font.
  * [bat](https://github.com/sharkdp/bat) - code highlighter
  * [eza](https://github.com/eza-community/eza) - better `ls`
- **Optional**:
  * [yazi](https://github.com/sxyazi/yazi) - file opener
  * [lazygit](https://github.com/jesseduffield/lazygit) - Git TUI

### Loading

```bash
# Download plugin
folder="$ZDOTDIR/plugins/zsh-fzf-nav" 
if [[ ! -d "$folder" ]]; then
  git clone --recurse-submodules --depth 1 "https://github.com/ivomac/zsh-fzf-nav" "$folder"
fi

# Load plugin
source "$folder/zsh-fzf-nav.plugin.zsh"
```

### Binding

The plugin defines a single entry point `_fzf-nav` to launch the menu. Bind it as you wish.

#### Super-tab

Open the menu with `<Tab>` when command line is empty, regular tab otherwise:

```bash
function fzf-nav() {
  if [[ -z "$BUFFER" ]]; then
    zle _fzf-nav
  else
    # if using fzf-tab plugin
    zle fzf-tab-complete
    # regular tab
    # zle expand-or-complete
  fi
}
zle -N fzf-nav

bindkey '^I' fzf-nav # Tab
```

## Configuration

Some functions and variables need to be defined for the plugin to function.
I recommend you paste and modify the configs below in your .zshrc.

### Environment Variables

```bash
# general
export FZF_DEFAULT_OPTS=...              # Used by the plugin when calling fzf

# plugin-specific
export FZF_NAV_OPEN="nnn"                # Command to open selected items (needed)
export FZF_NAV_TERMCMD="foot"            # Terminal for detached operations (needed)
export FZF_NAV_SEPARATOR=◇               # Separator in file${sep}line grep results. (default: ◇)

# FD options array. Runs at start and on ctrl-f modes.
# No default.
export FZF_NAV_FD_OPTS=(
    "--color=always"
    "--hidden"
    "--no-ignore"
    "--exclude='**/.git/**'"
    "--exclude='**/.cargo/**'"
    "--exclude='**/.npm/**'"
    ...
)

# Search function in grep/ctrl-r mode.
# No default.
export FZF_NAV_RG_OPTS=(
    "--line-number"                  # Show line numbers (needed).
    "--with-filename"                # Include filename in output (needed).
    "--color=always"
    "--hidden"
    "--no-ignore"
    "--smart-case"
    "--glob=!'**/.git/**'"
    "--glob=!'**/.parallel/**'"
    "--glob=!'**/.cargo/**'"
    "--glob=!'**/.npm/**'"
    "--glob=!'**/.pki/**'"
    "--glob=!'**/.venv**/**'"
    "--glob=!'**/__pycache__/**'"
    "--glob=!'**/.ipython/**'"
    "--glob=!'**/cache/**'"
    "--glob=!'**/.cache/**'"
    "--glob=!'**/.nvim/**'"
    "--glob=!'**/nvim/undo/**'"
    "--glob=!'**/.android/**'"
    "--glob=!'**/.mozilla/firefox/*/**'"
    "--glob=!'**/.stfolder/**'"
    "--glob=!'**/.steam/**'"
    "--glob=!'**/.aider*/**'"
    "--glob=!'**/.local/share/*/**'"
    "--glob=!'**/yazi/packages/**'"
)

# Secondary opener script. No default.
export FZF_NAV_USER_OPEN="lg-open"
# Example:
example-user-open {
  # Git modes work well with a git TUI like lazygit.
  if [[ -d "$1" ]]; then
    # If directory, cd and launch
    (cd "$1" && lazygit)
  else
    # If file, cd to parent and launch
    (cd "$(dirname "$1")" && lazygit)
  fi
}

# User-defined selection mode script. No default.
export FZF_NAV_USER_MODE="bookmarks"
# Example: Extract bookmarks from yazi.
example-user-mode {
  head -n1 "$XDG_STATE_HOME/yazi/.dds" \
  | cut -d, -f4- \
  | jq -r '.[] | "\(.path)$FZF_NAV_SEPARATOR\(.desc)"'
}

# Preview script. Has default.
export FZF_NAV_PREVIEW="preview"
# Default:
default-preview {
  # preview files and directories with bat and eza.
  file="$1"
  line="$2"

  ftype=$(file -b --mime "$file")
  flags=""
  if [[ -L "$file" ]]; then
    echo "Symlink -> $(readlink -f "$file")\n"
    flags+="--links"
  fi

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
}

```

## Usage

### Navigation Modes

The plugin supports several modes that you can switch between:

- **Search Mode** (default): Shows all files and directories.
- **Files Mode**: Shows only files.
- **Directories Mode**: Shows only directories.
- **Grep Mode**: Search within file contents.
- **Git Mode**: List git repositories.
- **Status Mode**: List git repositories with unclean status.
- **Fetch Mode**: List git repositories with unclean status after fetch (slow).
- **User Mode**: User-defined mode.

### Key Bindings

#### Mode Switching:
- `Ctrl+F`: Cycle through Search → Directories → Files.
- `Ctrl+R`: Switch to Grep mode.
- `Ctrl+G`: Cycle through Git → Status → Fetch modes.
- `Ctrl+T`: Switch to User mode (`fzf-nav-mode-user`).

#### Actions:
- `Enter`: Change to directory and open selections. Exits fzf.
- `Ctrl+O`: Open selection without changing directory and exiting.
- `Ctrl+U`: Open selection with user-defined command without exiting.
- `Ctrl+D`: Open selection in a detached terminal.

### Examples

1. **Quick file navigation**:
  - Search for a file/directory.
  - Press Enter to cd to the directory/file's parent and open it with `$FZF_NAV_OPEN`.

2. **Quick edits within files**:
  - Create a custom mode in your .zshrc:
    ```
    function nav-edit() {
      printf 'nvim $1 +$2' > '/tmp/edit.sh'
      chmod +x /tmp/edit.sh
      FZF_NAV_USER_OPEN='/tmp/edit.sh' _fzf-nav
    }
    ```
  - Run `nav-edit`
  - Press Ctrl+R to switch to grep mode.
  - Type your search term.
  - Press Ctrl+U to open a file in the editor at the highlighted line.
  - Exiting the editor will return you to the fzf-nav menu so you can edit another search result.

3. **Git repository management**:
  - Press Ctrl+G to switch to git mode.
  - Press Ctrl+G again to see repositories with modifications.
  - Press Ctrl+U on a repository to open lazygit (with config above).

4. **Bookmark navigation**:
  - Press Ctrl+T to show yazi bookmarks (with config above).
  - Press Enter on a bookmark to cd to it and open yazi.

