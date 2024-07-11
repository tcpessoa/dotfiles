#!/bin/bash

# xcode command line tools
xcode-select --install

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)";
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting;
# auto suggestions/completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# oh my zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";

brew install stow;
brew install pyenv;
# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
brew install htop;
brew install neovim;
brew install caffeine;  
brew install ripgrep
brew install lazygit

# Browsers
brew install --cask firefox;

# Code apps
# change iterm color and enable CMD + keys to navigate in line (natural text editing)
# Profiles -> Keys -> Key mappings -> Natural text editing
brew install --cask iterm2;

brew install --cask postman;
# To enable key repeat with vim extension
# defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
brew install --cask visual-studio-code;
brew install --cask docker;

# GUI apps
brew install --cask rectangle;
brew install --cask spotify;
brew install --cask karabiner-elements;
brew install --cask dbeaver-community;
