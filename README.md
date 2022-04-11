# Personal Dotfiles Collection

I use this repository together with a local bare git repository, alongside a git alias hooking `$HOME` up as the working tree. If you're confused, check out this [article](https://www.atlassian.com/git/tutorials/dotfiles).

# Reference

To install these dotfiles on a new location, do the following steps.

Clone the repository as a bare repo somewhere in your home folder.
```bash
git clone --bare git@github.com:mariomeissner/dotfiles.git dotfiles
```

Set up alias temporarily until we have the proper ZSH config loaded, which also contains this alias.
```bash
alias dotconf='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
```

Checkout the repo to get a copy of the config files in your home directory. This may fail if you already have a file with the same name. Delete them first.
```bash
dotconf checkout
```

Commands that should go to a post-checkout script or something.
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/wting/autojump $HOME/tools/autojump
$HOME/tools/autojump/install.sh

dotconf config --local status.showUntrackedFiles no
```

## TODO:
- [ ] Install ohmyzsh
- [ ] Install zsh plugins
