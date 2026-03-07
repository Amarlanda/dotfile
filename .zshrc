# ==========================================================================
#  ~/.zshrc - Zsh configuration file
#
#  Structure:
#    1. Debug / timing utilities
#    2. Color variables (ANSI escape codes)
#    3. PATH setup (deduplicated, portable $HOME)
#    4. History & shell options
#    5. Git helpers (credentials, clone wrapper)
#    6. Password / hosts helpers
#    7. Editor / reload helpers
#    8. GitKraken CLI wrapper
#    9. Misc utility functions (h, f, yourcli)
#   10. Aliases
#   11. Vim mode + cursor shape
#   12. Completions (fpath + single compinit)
#   13. External tool integrations (starship, zoxide, bun, sf, uv)
#   14. Interactive directory navigator (cd? with fzf)
#   15. main() - calls everything in order
#
#  Backup: ~/.zshrc.bak
# ==========================================================================

# --------------------------------------------------------------------------
# 1. Debug toggle
#    Set to "true" to print millisecond-precision timing for every function
#    called through time_func. Set to "false" for silent startup.
# --------------------------------------------------------------------------
DEBUG="true"

# Wrapper that measures how long a function takes to execute.
# Uses zsh's $EPOCHREALTIME (floating-point seconds since epoch) to get
# sub-millisecond precision, then converts to milliseconds for display.
# Usage: time_func <function_name>
function time_func() {
  local func_name="$1"
  if [[ "$DEBUG" == "true" ]]; then
    local start=$EPOCHREALTIME
    "$func_name"
    local end=$EPOCHREALTIME
    local duration=$(( (end - start) * 1000 ))
    printf "[DEBUG] %s took %.1fms\n" "$func_name" "$duration"
  else
    "$func_name"
  fi
}

# --------------------------------------------------------------------------
# 2. Color variables
#    ANSI escape codes stored in variables so they can be reused across
#    aliases, functions, and prompts without repeating raw escape sequences.
#    These are set early because other functions (block_url, gk-cli, cd?, etc.)
#    reference them.
# --------------------------------------------------------------------------
function define_colors() {
  BOLD='\033[1m'
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  RESET='\033[0m'
}

# --------------------------------------------------------------------------
# 3. PATH setup
#    All paths are deduplicated (each directory appears exactly once).
#    All hardcoded /Users/bob references replaced with $HOME for portability.
#    Paths prepended with higher priority go first; appended paths go last.
# --------------------------------------------------------------------------
function set_path() {
  # System essentials (prepended = highest priority)
  export PATH="/usr/local/bin:$PATH"

  # GNU coreutils from Homebrew (overrides macOS BSD versions)
  export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

  # Windsurf / Codeium editor integration
  export PATH="$HOME/.codeium/windsurf/bin:$PATH"

  # Salesforce CLI, system bins
  export PATH="$PATH:$HOME/cli/sf/bin:/bin:/usr/sbin:/sbin"

  # User-local binaries and Homebrew
  export PATH="$PATH:$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin"

  # Rust toolchain (cargo-installed binaries)
  export PATH="$PATH:$HOME/.cargo/bin"

  # Google Cloud SDK
  export PATH="$PATH:$HOME/Downloads/google-cloud-sdk/bin"

  # Node.js (pinned version via nvm)
  export PATH="$PATH:$HOME/.nvm/versions/node/v16.0.0/bin"

  # LaTeX and Java
  export PATH="$PATH:/Library/TeX/texbin:/usr/local/opt/openjdk/bin"

  # Blockchain toolchains (Foundry / Huff)
  export PATH="$PATH:$HOME/.foundry/bin:$HOME/.huff/bin"

  # GitKraken CLI
  export PATH="$PATH:$HOME/Library/Application Support/GitKrakenCLI"

  # Go workspace
  export GOPATH="$HOME/go"
  export GOBIN="$GOPATH/bin"
  export PATH="$PATH:$GOBIN:$HOME/.daml/bin"

  # zx - zshrc explorer CLI
  export PATH="$HOME/git/pers/zx/bin:$PATH"

  # Bun JavaScript runtime
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  # Claude Code maximum output token limit
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
}

# --------------------------------------------------------------------------
# 4. History & shell options
#    - Large history (90k entries) shared across all terminal sessions
#    - AUTO_CD lets you type a directory name to cd into it
#    - CORRECT offers typo corrections for commands
#    - NO_NOMATCH prevents errors when globbing finds no matches
# --------------------------------------------------------------------------
function configure_history() {
  HISTFILE=~/.zsh_history
  HISTSIZE=90000                # Max entries held in memory
  SAVEHIST=90000                # Max entries written to HISTFILE

  # History behaviour: timestamps, append, share across sessions, ignore
  # commands prefixed with a space, collapse duplicate blank lines
  setopt EXTENDED_HISTORY APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

  # Directory navigation shortcuts
  setopt AUTO_CD                # Type a dir name to cd into it
  setopt AUTO_PUSHD             # Push dirs onto the stack automatically
  setopt PUSHD_IGNORE_DUPS      # Don't duplicate entries on the dir stack
  setopt PUSHD_SILENT           # Don't print the dir stack after pushd/popd

  # Input & completion behaviour
  setopt CORRECT                # Offer to correct mistyped commands
  setopt COMPLETE_IN_WORD       # Allow tab-completion from within a word
  setopt ALWAYS_TO_END          # Move cursor to end of word after completion
  setopt MENU_COMPLETE          # Show completion menu on first tab press
  setopt NO_NOMATCH             # Pass unmatched globs through literally
  setopt INTERACTIVE_COMMENTS   # Allow # comments in interactive shells
}

# --------------------------------------------------------------------------
# 5. Git helpers
#    - load_git_creds: sources ~/.git_credentials (sets PERSONAL_GIT_USERNAME
#      and PERSONAL_GIT_TOKEN as env vars)
#    - clone: convenience wrapper that injects stored credentials into the
#      clone URL. Accepts a full https:// URL or just a repo name (assumes
#      your GitHub username as the owner).
# --------------------------------------------------------------------------
function load_git_creds() {
  [ -f ~/.git_credentials ] && source ~/.git_credentials
}

function clone() {
  local repo="$1"
  if [[ "$repo" =~ ^https:// ]]; then
    # Full URL provided - strip the https:// prefix and re-add with creds
    git clone "https://${PERSONAL_GIT_USERNAME}:${PERSONAL_GIT_TOKEN}@${repo#https://}"
  else
    # Short name provided - assume personal GitHub repo
    git clone "https://${PERSONAL_GIT_USERNAME}:${PERSONAL_GIT_TOKEN}@github.com/${PERSONAL_GIT_USERNAME}/${repo}.git"
  fi
}

# --------------------------------------------------------------------------
# 6. Password / hosts helpers
#    - get_decoded_password: reads the base64-encoded password from ~/.bobski
#      and decodes it. Used by block_url to authenticate sudo.
#    - block_url: appends a 127.0.0.1 entry to /etc/hosts to block a domain.
#      Validates the hostname against a strict alphanumeric regex to prevent
#      command injection via crafted input.
# --------------------------------------------------------------------------
function get_decoded_password() {
  base64 --decode < "$HOME/.bobski"
}

function block_url() {
  [[ -z "$1" ]] && echo "Usage: block_url [URL]" && return 1
  local url="$1"

  # Only allow valid hostname characters (letters, digits, dots, hyphens)
  # to prevent injection of newlines or shell metacharacters into /etc/hosts
  if [[ ! "$url" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "${RED}Invalid hostname:${RESET} $url"
    return 1
  fi

  local password
  password=$(get_decoded_password)
  echo "$password" | sudo -S -- bash -c "echo '127.0.0.1 $url' >> /etc/hosts"
  echo "${GREEN}$url added to /etc/hosts${RESET}"
}

# --------------------------------------------------------------------------
# 7. Editor / reload helpers
#    - edit_and_source_zshrc: opens this file in neovim, then re-sources it
#      after you quit the editor (only if nvim exits successfully).
#    - reload_zsh: forces a fresh compinit (useful after adding new
#      completion scripts without restarting the shell).
# --------------------------------------------------------------------------
function edit_and_source_zshrc() {
  nvim ~/.zshrc && source ~/.zshrc
}

function reload_zsh() {
  autoload -U compinit && compinit
}

# --------------------------------------------------------------------------
# 8. GitKraken CLI wrapper
#    - "kraken c"    : stages all changes and creates an AI-generated commit
#    - "kraken"      : opens the current repo in GitKraken GUI
#    - "kraken /path": opens a specific repo in GitKraken GUI
# --------------------------------------------------------------------------
function gk-cli() {
  if [[ "$1" == "c" ]]; then
    echo "${YELLOW}Staging all changes and committing with AI...${RESET}"
    git add -A && gk ai commit --all
    return
  fi
  local target_dir="${1:-$(pwd)}"
  echo "${BLUE}Opening GitKraken with repository:${RESET} $target_dir"
  open "$target_dir" -a "GitKraken"
}

# --------------------------------------------------------------------------
# 9. Misc utility functions
#    - yourcli : launches custom Rust/Go binary from personal projects
#    - h [N]   : shows the last N history entries with timestamps (default 20)
#    - f [N]   : fuzzy-find directories up to depth N (default 1)
# --------------------------------------------------------------------------

function yourcli() {
  "$HOME/git/pers/cv_rust/backend/go-bin/go-bin"
}

function h() {
  local n=${1:-20}
  # fc -l: list history; -t: format timestamps; -$n: last N entries
  fc -l -t '(%d-%m-%Y %H:%M:%S)' -$n
}

function f() {
  find . -maxdepth ${1:-1} -type d | fzf
}

# Fuzzy folder search with fzf, cd into selection
#   zo         - search all folders recursively
#   zo -d N    - limit search to depth N
#   zo <query> - pre-filter fzf with query
function zo() {
  local depth=""
  local query=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d) depth="$2"; shift 2 ;;
      *)  query="$1"; shift ;;
    esac
  done

  local cmd="find . -type d -not -path '*/\.*'"
  [[ -n "$depth" ]] && cmd="find . -maxdepth $depth -type d -not -path '*/\.*'"

  local dir
  dir=$(eval "$cmd" 2>/dev/null | fzf --height 40% --reverse --preview "ls -la {}" --preview-window=right:50% --query="$query")

  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}

# Generic machine connection menu
# Reads config from ~/.config/machines.conf using a prefix (M1, M2, etc.)
#   Enter/1 - SSH in current window
#   2       - SSH in new Zellij tab
#   3       - RDM VNC (windowed)
#   4       - RDM VNC (fullscreen)
#   5       - RDM SSH (windowed)
#   6       - RDM SSH (fullscreen)
function machine_connect() {
  local prefix="$1"
  local choice="$2"
  source "$HOME/.config/machines.conf"

  local name="${(P)${:-${prefix}_NAME}}"
  local host="${(P)${:-${prefix}_HOST}}"
  local user="${(P)${:-${prefix}_USER}}"
  local pass="${(P)${:-${prefix}_PASS}}"
  local rdm_vnc="${(P)${:-${prefix}_RDM_VNC}}"

  if [[ -z "$host" ]]; then
    echo "${RED}No config found for ${prefix} in ~/.config/machines.conf${RESET}"
    return 1
  fi

  if [[ -z "$choice" ]]; then
    echo "${BOLD}${BLUE}${name}${RESET} (${host})"
    echo ""
    echo "  ${YELLOW}0${RESET}          Test all machines (SSH + VNC)"
    echo "  ${YELLOW}1${RESET} / ${YELLOW}Enter${RESET}  SSH in current window"
    echo "  ${YELLOW}2${RESET}          SSH in new Zellij tab"
    echo "  ${YELLOW}3${RESET}          VNC Screen Sharing (windowed)"
    echo "  ${YELLOW}4${RESET}          VNC Screen Sharing (fullscreen)"
    echo ""
    echo -n "Select: "
    read -rk1 choice
    echo ""
  fi

  case "$choice" in
    0)
      test_machines
      return
      ;;
    1|$'\n')
      zellij action rename-pane "SSH $name" 2>/dev/null
      sshpass -p "$pass" ssh "${user}@${host}"
      zellij action rename-pane "" 2>/dev/null
      ;;
    2)
      zellij action new-tab --name "SSH $name"
      sleep 0.3
      zellij action write-chars "zellij action rename-pane 'SSH $name' && sshpass -p $pass ssh ${user}@${host} && zellij action rename-pane ''"
      zellij action write 13
      ;;
    3|4)
      open "vnc://${user}:${pass}@${host}"
      if [[ "$choice" == "4" ]]; then
        sleep 2
        osascript -e 'tell application "System Events" to tell process "Screen Sharing" to set value of attribute "AXFullScreen" of window 1 to true'
      fi
      ;;
    *)
      echo "${RED}Invalid option${RESET}"
      return 1
      ;;
  esac
}

# Unified machine launcher
# Usage: m              → machine picker then action menu
#        m m1           → action menu for M1
#        m m2 2         → SSH M2 in new Zellij tab (skip menus)
#        m all          → run action on all machines
#        m test         → test connectivity for all machines
MACHINE_PREFIXES=(M1 M2 M3)

function m() {
  source "$HOME/.config/machines.conf"
  local target="$1"
  local action="$2"

  # Pick machine if not specified
  if [[ -z "$target" ]]; then
    echo "${BOLD}${BLUE}Machines${RESET}"
    echo ""
    local i=1
    for prefix in "${MACHINE_PREFIXES[@]}"; do
      local name="${(P)${:-${prefix}_NAME}}"
      local host="${(P)${:-${prefix}_HOST}}"
      echo "  ${YELLOW}${i}${RESET} / ${YELLOW}${prefix:l}${RESET}  ${name} (${host})"
      ((i++))
    done
    echo "  ${YELLOW}a${RESET} / ${YELLOW}all${RESET}   All machines"
    echo "  ${YELLOW}t${RESET} / ${YELLOW}test${RESET}  Test connectivity"
    echo ""
    echo -n "Select: "
    read -r target
    echo ""
  fi

  # Resolve target
  case "${target:l}" in
    1|m1)  machine_connect M1 "$action" ;;
    2|m2)  machine_connect M2 "$action" ;;
    3|m3)  machine_connect M3 "$action" ;;
    a|all)
      if [[ -z "$action" ]]; then
        echo "${BOLD}${BLUE}All Machines${RESET} — pick action"
        echo ""
        echo "  ${YELLOW}1${RESET} / ${YELLOW}Enter${RESET}  SSH each in Zellij tabs"
        echo "  ${YELLOW}2${RESET}          VNC Screen Sharing (all)"
        echo "  ${YELLOW}3${RESET}          Deploy Ansible playbook"
        echo ""
        echo -n "Select: "
        read -rk1 action
        echo ""
      fi
      case "$action" in
        1|$'\n')
          for prefix in "${MACHINE_PREFIXES[@]}"; do
            machine_connect "$prefix" 2
          done
          ;;
        2)
          for prefix in "${MACHINE_PREFIXES[@]}"; do
            machine_connect "$prefix" 3
          done
          ;;
        3)
          echo "${BOLD}Running Ansible against all machines...${RESET}"
          (cd "$HOME/git/pers/ansible-local" && source venv/bin/activate && ansible-playbook site.yml -v)
          ;;
        *) echo "${RED}Invalid option${RESET}"; return 1 ;;
      esac
      ;;
    t|test) test_machines ;;
    *) echo "${RED}Unknown target: ${target}${RESET}"; return 1 ;;
  esac
}

# Keep m1/m2/m3 as shortcuts
function m1() { machine_connect M1 "$1"; }
function m2() { machine_connect M2 "$1"; }
function m3() { machine_connect M3 "$1"; }

# Test SSH and VNC connectivity to all machines in parallel
function test_machines() {
  source "$HOME/.config/machines.conf"
  local tmpdir=$(mktemp -d)
  local pids=()

  for prefix in M1 M2 M3; do
    local name="${(P)${:-${prefix}_NAME}}"
    local host="${(P)${:-${prefix}_HOST}}"
    local user="${(P)${:-${prefix}_USER}}"
    local pass="${(P)${:-${prefix}_PASS}}"

    # SSH test
    (
      if sshpass -p "$pass" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${user}@${host}" "echo ok" &>/dev/null; then
        echo "pass" > "$tmpdir/${prefix}_ssh"
      else
        echo "fail" > "$tmpdir/${prefix}_ssh"
      fi
    ) &
    pids+=($!)

    # VNC test (port 5900)
    (
      if nc -z -w 5 "$host" 5900 &>/dev/null; then
        echo "pass" > "$tmpdir/${prefix}_vnc"
      else
        echo "fail" > "$tmpdir/${prefix}_vnc"
      fi
    ) &
    pids+=($!)
  done

  # Wait for all tests
  for pid in "${pids[@]}"; do wait "$pid"; done

  # Print results
  echo ""
  for prefix in M1 M2 M3; do
    local name="${(P)${:-${prefix}_NAME}}"
    local ssh_result=$(cat "$tmpdir/${prefix}_ssh" 2>/dev/null || echo "fail")
    local vnc_result=$(cat "$tmpdir/${prefix}_vnc" 2>/dev/null || echo "fail")
    local ssh_icon=$([[ "$ssh_result" == "pass" ]] && echo "${GREEN}OK${RESET}" || echo "${RED}FAIL${RESET}")
    local vnc_icon=$([[ "$vnc_result" == "pass" ]] && echo "${GREEN}OK${RESET}" || echo "${RED}FAIL${RESET}")
    echo "  ${BOLD}${name}${RESET}  SSH: ${ssh_icon}  VNC: ${vnc_icon}"
  done
  echo ""

  rm -rf "$tmpdir"
}

# --------------------------------------------------------------------------
# 10. Aliases
#     Single-quotes are used for aliases that contain $variables or $(cmds)
#     so they expand at invocation time, not at definition time. This is
#     important for the ".." alias which needs the current pwd each time.
# --------------------------------------------------------------------------
function zellij_attach_last() {
  echo "${BLUE}[z] Checking for zellij sessions...${RESET}"
  local sessions
  sessions=$(timeout 3 zellij list-sessions 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 124 ]]; then
    echo "${YELLOW}[z] list-sessions timed out, starting new session...${RESET}"
    zellij
    return
  fi

  if [[ $exit_code -ne 0 ]] || [[ -z "$sessions" ]]; then
    echo "${YELLOW}[z] No sessions found, starting new session...${RESET}"
    zellij
    return
  fi

  echo "${GREEN}[z] Found sessions:${RESET}"
  echo "$sessions"
  # Grab the most recently created session name (last line, first field)
  local last_session
  last_session=$(echo "$sessions" | tail -1 | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
  echo "${GREEN}[z] Attaching to session: ${last_session}...${RESET}"
  zellij attach "$last_session"
}

function define_aliases() {
  alias vi='nvim'                                   # Always use neovim
  alias zshrc='edit_and_source_zshrc'               # Quick-edit this file
  alias python='python3'                            # Default to python3
  alias pip='pip3'                                  # Default to pip3
  alias sfdx='sf'                                   # Salesforce CLI rename
  alias l="lsd -ltha"                               # Pretty ls with lsd
  # Print a coloured "moving from X to Y" message, then cd up one level
  alias ..='noglob echo "${BOLD}moving from${RESET} ${YELLOW}$(pwd)${RESET} to ${GREEN}$(dirname "$(pwd)")${RESET}"; cd ..'
  alias cls="reset; clear"                          # Full terminal reset
  alias c="source ~/.env && claude --dangerously-skip-permissions"  # Claude Code
  alias k="kubectl"                                 # Kubernetes shorthand
  alias ctx="kubectl config get-contexts"           # List k8s contexts
  alias z="zellij_attach_last"                        # Zellij attach last session
  alias zt="zellij --layout tree"                     # Zellij with file tree
  alias ha="zellij --layout htop-all"                  # htop on all 3 machines
  alias kraken='gk-cli'                             # GitKraken wrapper
  # m1 is now a function (see section 9)
}

# --------------------------------------------------------------------------
# 11. Vim mode + cursor shape
#     - configure_vim_mode: enables vi keybindings and restores ctrl-R for
#       reverse history search (which vi mode disables by default).
#     - setup_cursor: changes the terminal cursor shape depending on the
#       current vim mode:
#         Normal mode (vicmd) -> yellow block cursor  (\e[2 q)
#         Insert mode         -> yellow bar cursor    (\e[5 q)
#       A precmd hook resets the cursor before each new prompt so other
#       programs don't inherit the modified cursor.
# --------------------------------------------------------------------------
function configure_vim_mode() {
  bindkey -v                                        # Enable vi keybindings
  bindkey '^R' history-incremental-search-backward  # Restore ctrl-R search
}

function setup_cursor() {
  # ZLE widget: fires on line init and whenever the keymap changes
  function zle-line-init zle-keymap-select {
    if [[ "${KEYMAP}" == "vicmd" ]]; then
      # Normal mode: yellow block cursor
      echo -ne '\e[1;33m\e[2 q'
    else
      # Insert mode: yellow bar cursor
      echo -ne '\e[1;33m\e[5 q'
    fi
    zle reset-prompt
  }
  # Register the widget with ZLE
  zle -N zle-line-init
  zle -N zle-keymap-select

  # Reset cursor to default before each prompt so other programs aren't
  # affected by the vim-mode cursor override
  autoload -Uz add-zsh-hook
  function restore_cursor() {
    echo -ne '\e[0 q'        # Reset cursor shape to default
    echo -ne '\e[0m'         # Reset text color
  }
  add-zsh-hook -D precmd restore_cursor   # Remove any stale hook first
  add-zsh-hook precmd restore_cursor      # Then register fresh
}

# --------------------------------------------------------------------------
# 12. Completions
#     All fpath additions are gathered here so that compinit only needs to
#     run once (it's expensive - scans all completion files on every call).
#     Sources: Homebrew, custom ~/.zsh/completion, Docker Desktop.
# --------------------------------------------------------------------------
function setup_completions() {
  # Homebrew-installed completions (e.g. git, docker, kubectl)
  if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  fi

  # Custom user completions
  fpath=(~/.zsh/completion $fpath)

  # Docker Desktop CLI completions
  fpath=($HOME/.docker/completions $fpath)

  # Initialize the completion system (once, after all fpath entries)
  autoload -Uz compinit
  compinit

  # zx completions
  source <(zx completion zsh)
}

# --------------------------------------------------------------------------
# 13. External tool integrations
#     Each tool is guarded with a file-existence check so the shell doesn't
#     error if a tool isn't installed. eval "$(tool init zsh)" is the
#     standard pattern for tools that inject shell hooks/functions.
# --------------------------------------------------------------------------
function setup_external_tools() {
  # Salesforce CLI autocomplete
  local sf_setup="$HOME/Library/Caches/sf/autocomplete/zsh_setup"
  [[ -f "$sf_setup" ]] && source "$sf_setup"

  # Bun JavaScript runtime completions
  [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

  # UV (Python package manager) virtual environment
  [[ -f "$HOME/git/pers/cursor2figma/n8n/scripts/.uvbin/env" ]] && \
    . "$HOME/git/pers/cursor2figma/n8n/scripts/.uvbin/env"

  # Starship cross-shell prompt (Rust-based, replaces p10k)
  eval "$(starship init zsh)"

  # Zoxide smarter cd (tracks frequently visited directories)
  eval "$(zoxide init zsh)"
}

# --------------------------------------------------------------------------
# 14. Interactive directory navigator (cd?)
#     A progressive directory picker powered by fzf. Lets you drill into
#     nested directories one level at a time with a preview pane.
#
#     Controls:
#       Enter  - descend into the selected directory (or cd if it's a leaf)
#       /      - type a path manually (absolute or relative to current)
#       Esc    - abort and cd to wherever you've navigated so far
# --------------------------------------------------------------------------
function 'cd?'() {
  local path="."

  while true; do
    # Show the path we've built so far
    echo "${BLUE}Current path: $path${RESET}"

    # Build a newline-separated list of immediate subdirectories
    local dirs=""
    for item in "$path"/*; do
      if [ -d "$item" ]; then
        dirs="$dirs${item#$path/}
"
      fi
    done

    # If there are no subdirectories, we've reached a leaf - navigate there
    if [[ -z "$dirs" ]]; then
      echo "No subdirectories found."
      cd "$path"
      return
    fi

    # Present directories in fzf with a file-listing preview pane
    local selection=$(/opt/homebrew/bin/fzf --height 40% --reverse --inline-info \
                      --preview "ls -la $path/{}" --preview-window=right:60% \
                      --prompt="Select directory or type / to enter path: " \
                      --bind="/:abort" --expect="/,enter" <<< "$dirs")

    # Empty selection means the user pressed Esc - cd to current path
    if [[ -z "$selection" ]]; then
      cd "$path"
      return
    fi

    # fzf --expect outputs two lines: the key pressed, then the selection
    local key=$(echo "$selection" | head -1)
    local dir=$(echo "$selection" | tail -1)

    if [[ "$key" == "/" ]]; then
      # User pressed / - prompt for manual path input
      echo -n "Enter path: "
      read -r input_path
      if [[ -d "$input_path" ]]; then
        path="$input_path"                  # Absolute path provided
      elif [[ -d "$path/$input_path" ]]; then
        path="$path/$input_path"            # Relative to current path
      else
        echo "${RED}Path not found:${RESET} $input_path"
        sleep 1
      fi
    elif [[ "$key" == "enter" && -n "$dir" ]]; then
      # User selected a directory - descend into it
      path="$path/$dir"

      # Check if this directory has any subdirectories
      local has_subdirs=0
      for item in "$path"/*; do
        if [ -d "$item" ]; then
          has_subdirs=1
          break
        fi
      done

      # If it's a leaf directory (no children), we're done
      if [[ $has_subdirs -eq 0 ]]; then
        cd "$path"
        return
      fi
      # Otherwise loop again to pick the next level
    else
      # Fallback: cd to wherever we are
      cd "$path"
      return
    fi
  done
}

# --------------------------------------------------------------------------
# 15. Main - orchestrate all setup
#     Every function is called through time_func so startup performance
#     can be profiled when DEBUG="true". The order matters:
#       1. define_colors  - needed by functions that print coloured output
#       2. load_git_creds - populates PERSONAL_GIT_* vars for clone()
#       3. set_path       - must run before tools that depend on PATH
#       4-6. history, aliases, vim - independent, order doesn't matter
#       7. setup_cursor   - registers ZLE widgets (after vim mode is set)
#       8. setup_completions - compinit runs once, after all fpath additions
#       9. setup_external_tools - evals (starship, zoxide) go last since
#          they're the slowest and don't affect anything above
# --------------------------------------------------------------------------
function main() {
  time_func define_colors
  time_func load_git_creds
  time_func set_path
  time_func configure_history
  time_func define_aliases
  time_func configure_vim_mode
  time_func setup_cursor
  time_func setup_completions
  time_func setup_external_tools
}

main

# Zellij vtab dev: kill sessions, rebuild, relaunch
alias xx="cd ~/git/pers/zellji-websrvr-manager ; ZELLIJ_LOG_LEVEL=debug zellij --layout ./zellij-vtab/layout.kdl"

# London network CLI
export PATH="$HOME/git/pers/service-registry-discovey/bin:$PATH"
alias ldn=ldnctl

# London network - Mac Mini hostnames (also in /etc/hosts on each node)
# mini-1 = 10.0.0.11, mini-2 = 10.0.0.22, mini-3 = 10.0.0.33

# add Pulumi to the PATH
export PATH=$PATH:/Users/bob/.pulumi/bin

# Portainer SSH tunnel to mini-1
function portainer() {
  ssh -f -N -L 9444:localhost:9444 amar@10.0.0.11
  echo "${GREEN}Portainer tunnel active → https://localhost:9444${RESET}"
}
