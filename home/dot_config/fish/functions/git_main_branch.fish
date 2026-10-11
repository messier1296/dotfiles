function git_main_branch --description 'Find the main branch using Oh My Zsh ordering'
    command git rev-parse --git-dir >/dev/null 2>&1; or return
    for prefix in refs/heads refs/remotes/origin refs/remotes/upstream
        for branch in main trunk mainline default stable master
            if command git show-ref -q --verify "$prefix/$branch"
                echo "$branch"
                return 0
            end
        end
    end
    for remote in origin upstream
        set -l ref (command git rev-parse --abbrev-ref "$remote/HEAD" 2>/dev/null)
        if string match -q "$remote/*" -- "$ref"
            string replace "$remote/" '' -- "$ref"
            return 0
        end
    end
    echo master
    return 1
end
