# dotfiles management

This repo is to manage dotfiles and installing them using stow

# MAC OS

Install homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Show all hidden files in Finder:
```sh
defaults write com.apple.Finder AppleShowAllFiles true;
killall Finder
```

# VS code

Install extensions by 

```sh
cd vscode; cat extensions.txt | xargs -L 1 code --install-extension
```
