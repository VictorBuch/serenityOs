#!/bin/sh

set -e  # Exit on any error

# Automated script to install my dotfiles for serenity machine
echo "Generating SSH key. Please wait..."
ssh-keygen -t ed25519 -C "victorbuch@protonmail.com" -N "" -f ~/.ssh/id_ed25519

eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519

cat ~/.ssh/id_ed25519.pub

echo "Add the key to Github and then press Enter to continue..."
read -r  # Wait for user to press Enter

# Clone dotfiles
nix-shell -p git --run "git clone git@github.com:VictorBuch/serenityOs.git ~/.nixos"

cd ~/.nixos

sudo rm -rf ~/.nixos/hosts/serenity/hardware-configuration.nix
sudo cp /etc/nixos/hardware-configuration.nix ~/.nixos/hosts/serenity/hardware-configuration.nix

git add .

# Rebuild system
sudo nixos-rebuild switch --flake ~/.nixos#serenity

# Install and build home-manager configuration (commented out)
# nix run home-manager/master --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.nixos#user