function alert --description 'Notify when the preceding command finishes'
    set -l previous_status $status
    set -l icon terminal
    if test $previous_status -ne 0
        set icon error
    end
    set -l message (history --max=1 | string replace -r '[;&|]\s*alert$' '')
    command notify-send --urgency=low -i "$icon" "$message"
end
