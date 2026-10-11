# Machine-specific paths and secrets belong in this untracked file.
if test -f "$__fish_config_dir/local.fish"
    source "$__fish_config_dir/local.fish"
end

set -q PROTO_HOME; or set -gx PROTO_HOME "$HOME/.proto"
set -q NVM_DIR; or set -gx NVM_DIR "$HOME/.nvm"

fish_add_path --global --path "$HOME/.local/bin" "$HOME/bin" \
    "$HOME/.cargo/bin" "$PROTO_HOME/shims" "$PROTO_HOME/bin" \
    "$HOME/.juliaup/bin" "$HOME/.opencode/bin"
fish_add_path --global --path --append /opt/nvim-linux-x86_64/bin

if not status is-interactive
    return
end

set -g fish_greeting
fish_vi_key_bindings

# Completion candidates come from Carapace; fifc provides the Tab picker.
set -gx fifc_editor nvim
set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
if command -sq carapace
    carapace _carapace | source
end

if command -sq zoxide
    zoxide init fish | source
end

# Keep abbreviations small; the existing aliases remain available as well.
abbr --add --global gst 'git status'
abbr --add --global dc 'docker compose'

# Retain an inherited Node version; otherwise activate nvm's default.
if test -s "$NVM_DIR/nvm.sh"; and functions -q bass
    if not set -q NVM_BIN; or not contains -- "$NVM_BIN" $PATH; or not test -x "$NVM_BIN/node"
        nvm use --silent default
    end
end

if command -sq npm
    set -l npm_global_prefix (command npm prefix -g 2>/dev/null)
    if test -n "$npm_global_prefix"
        fish_add_path --global --path "$npm_global_prefix/bin"
    end
end

# Personal aliases from ~/.zshrc.
alias contest 'python3 scripts/create_contest.py'
alias submit 'python3 scripts/generate_submit.py'
alias run 'python3 scripts/run_test_cases.py'
alias check 'python3 scripts/check_expected_outputs.py'
alias make 'python3 scripts/generate_expected_outputs.py'
alias fetch 'python3 scripts/import_fetch_samples.py'
alias t 'python3 scripts/fetch_and_check_samples.py'
if command -sq eza
    alias ls eza
    alias ll 'eza -la --icons'
    alias la 'eza -a'
    alias l eza
    alias tree 'eza --tree --icons'
end
if command -sq bat
    alias cat bat
else if command -sq batcat
    alias cat batcat
end
if not command -sq fd; and command -sq fdfind
    alias fd fdfind
end

if set -q DOTFILES_DOWNLOADS; and test -d "$DOTFILES_DOWNLOADS"
    set -gx wd "$DOTFILES_DOWNLOADS"
else if test -d "$HOME/Downloads"
    set -gx wd "$HOME/Downloads"
else if command -sq xdg-user-dir
    set -l downloads (xdg-user-dir DOWNLOAD 2>/dev/null)
    if test -n "$downloads"; and test -d "$downloads"
        set -gx wd "$downloads"
    end
end

# Common aliases from the Oh My Zsh git plugin.
alias g git
alias ga 'git add'
alias gaa 'git add --all'
alias gb 'git branch'
alias gcb 'git checkout -b'
alias gco 'git checkout'
alias gc 'git commit -v'
alias gcmsg 'git commit -m'
alias gd 'git diff'
alias gds 'git diff --staged'
alias gf 'git fetch'
alias gl 'git pull'
alias glog 'git log --oneline --decorate --graph'
alias gp 'git push'
alias grb 'git rebase'
alias gst 'git status'

if test -f "$HOME/.julia/juliaup/completions/fish.fish"
    source "$HOME/.julia/juliaup/completions/fish.fish"
end

if command -sq starship
    starship init fish | source
end
