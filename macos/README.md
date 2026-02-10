# MACOS SETUP

Using Brewfile and ansible to bootstrap environment for development on macos 

## Usage

[install.sh](install.sh) is base script that installs all of the software and it's configuration:
- Install tools from Brewfile
- Run ansible roles from playbook.yml
    - Configure zsh
    - Configure neovim
    - Configure vscode
    - Configure gvm/golang
    - Configure nvm/node
    - Configure cargo/rustc
    - Configure pyenv/python