# nvm's documented fish integration via bass; escape arguments for its bash eval.
function nvm --description 'Use the existing bash nvm installation from fish'
    if not test -s "$NVM_DIR/nvm.sh"
        echo "nvm: missing $NVM_DIR/nvm.sh" >&2
        return 1
    end
    bass source (string escape -- "$NVM_DIR/nvm.sh") --no-use ';' nvm (string escape -- $argv)
end
