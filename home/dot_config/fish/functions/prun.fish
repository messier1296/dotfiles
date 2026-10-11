function prun --description 'Run a machine-local programming contest script'
    if not set -q DOTFILES_PRUN_SCRIPT; or not test -x "$DOTFILES_PRUN_SCRIPT"
        echo 'prun: set DOTFILES_PRUN_SCRIPT in ~/.config/fish/local.fish to an executable script' >&2
        return 1
    end
    command "$DOTFILES_PRUN_SCRIPT" $argv
end
