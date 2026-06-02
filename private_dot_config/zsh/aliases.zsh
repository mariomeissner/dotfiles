# Listings
alias ll="eza -la"
alias la="eza -a"
alias lt="eza --tree"

# Navigation
alias md="mkdir -p"

# Prefer Homebrew's newer rsync over the macOS system rsync.
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  alias rsync="$HOMEBREW_PREFIX/bin/rsync"
elif [ -x /opt/homebrew/bin/rsync ]; then
  alias rsync="/opt/homebrew/bin/rsync"
elif [ -x /usr/local/bin/rsync ]; then
  alias rsync="/usr/local/bin/rsync"
fi

# Git essentials
alias g="git"
alias gs="git status"
alias gsb="git status --short --branch"
alias ga="git add"
alias gaa="git add --all"
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git pull"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gco="git checkout"
alias gsw="git switch"
alias gswc="git switch --create"
alias gb="git branch"
alias gba="git branch --all"
alias gf="git fetch"
alias gfa="git fetch --all --prune"
alias grb="git rebase"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"
alias glog="git log --oneline --decorate --graph"
alias gloga="git log --oneline --decorate --graph --all"
