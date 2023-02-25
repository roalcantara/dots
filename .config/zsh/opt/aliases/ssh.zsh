# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# SSH: https://docs.github.com/en/github/authenticating-to-github/about-ssh
alias ssh="ssh $SSH_CONFIG $SSH_ID "
alias ssh-copy-id="ssh-copy-id $SSH_ID"
alias pubkey='find ~/.ssh/*.pub | fzf --ansi | xargs cat | tr -d "\n" | pbcopy && echo "=> Public key copied to pasteboard."'
