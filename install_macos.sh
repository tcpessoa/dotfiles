#!/bin/bash

# xcode command line tools
xcode-select --install

# General software
brew install zsh;
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)";
brew install stow;
brew install python3;
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash;
brew install htop;
brew install neovim;
brew install caffeine;  
brew install yarn;

# Browsers
brew cask install google-chrome;

# Code apps
brew cask install postman;
brew cask install visual-studio-code;
brew cask install iterm2;
brew cask install docker;

# GUI apps
brew install --cask rectangle;
brew cask install spotify;
brew install --cask karabiner-elements;
brew install --cask dbeaver-community;
