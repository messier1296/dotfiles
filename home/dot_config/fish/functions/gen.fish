function gen --description 'Run a casegen binary with an optional count'
    if not set -q argv[1]; or test -z "$argv[1]"
        echo 'usage: gen <name> [count]' >&2
        return 1
    end
    set -l case_count 1
    if set -q argv[2]; and test -n "$argv[2]"
        set case_count "$argv[2]"
    end
    command cargo run -p casegen --bin "$argv[1]" -- --count "$case_count"
end
