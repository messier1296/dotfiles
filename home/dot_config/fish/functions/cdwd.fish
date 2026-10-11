function cdwd --description 'Go to the locally configured downloads directory'
    if not set -q wd; or not test -d "$wd"
        echo 'cdwd: set DOTFILES_DOWNLOADS in ~/.config/fish/local.fish' >&2
        return 1
    end
    builtin cd -- "$wd"
end
