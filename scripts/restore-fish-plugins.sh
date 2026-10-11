#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
config_root=${XDG_CONFIG_HOME:-"$HOME/.config"}
manifest="$config_root/fish/fish_plugins"
stored_manifest="$repository/home/dot_config/fish/fish_plugins"

if [ ! -f "$manifest" ]; then
    echo 'Apply the dotfiles first: fish_plugins is missing.' >&2
    exit 1
fi
if ! cmp -s "$manifest" "$stored_manifest"; then
    echo 'fish_plugins differs from this repository. Apply/reconcile the dotfiles first.' >&2
    exit 1
fi

for tool in fish curl sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing prerequisite: $tool (see README.md)." >&2
        exit 1
    fi
done

fisher_revision=$(sed -n 's#^jorgebucaran/fisher@##p' "$manifest")
if ! printf '%s\n' "$fisher_revision" | grep -Eq '^[0-9a-f]{40}$'; then
    echo 'fish_plugins must pin exactly one Fisher commit.' >&2
    exit 1
fi

temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
trap 'exit 1' HUP INT TERM
curl -q --fail --silent --show-error --location --proto '=https' \
    --connect-timeout 10 --max-time 60 --retry 2 \
    "https://raw.githubusercontent.com/jorgebucaran/fisher/$fisher_revision/functions/fisher.fish" \
    --output "$temporary/fisher.fish"
printf '%s  %s\n' \
    0fb6c81ae3003e95b5671766fa6c25c3597066e29965b7772f6c1b007387356d \
    "$temporary/fisher.fish" | sha256sum --check --status

# Noninteractive startup avoids terminal/WSL notification probes during setup.
fish -c 'source "$argv[1]"; fisher update; or exit 1;
    set -l expected (string match -r ".+" < "$argv[2]");
    test (count (fisher list)) -eq (count $expected); or exit 1;
    for plugin in $expected; contains -- "$plugin" (fisher list); or exit 1; end' \
    "$temporary/fisher.fish" "$manifest"

# fish-abbreviation-tips caches aliases/abbreviations at installation time.
# Rebuild once with the interactive config loaded, without contacting Windows.
SSH_CLIENT=dotfiles-setup fish -i -c 'functions -q __abbr_tips_init; and __abbr_tips_init'
printf '%s\n' 'Fish plugins restored. Start a new fish session.'
