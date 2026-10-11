function gcm --description 'Check out the main branch, as in Oh My Zsh'
    set -l main_branch (git_main_branch)
    if test -z "$main_branch"
        return 1
    end
    command git checkout "$main_branch" $argv
end
