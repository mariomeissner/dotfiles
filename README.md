# Personal Dotfiles Collection

I use this repository together with a local bare git repository, alongside a git alias hooking `$HOME` up as the working tree. If you're confused, check out this [article](https://www.atlassian.com/git/tutorials/dotfiles).

The alias for 

# Reference

To install these dotfiles on a new location, do the following steps.

Set up alias temporarily until we have the proper ZSH config loaded, which also contains this alias.
```bash
alias dotconf='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
```

