#!/usr/bin/env bash
# Install brew software
brew bundle

# Run ansible tasks
ansible-playbook playbook.yml
