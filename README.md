This is for the normal nixos. Needs to be installed normally and don't require any special disk setup.

sudo nixos-rebuild boot --flake github:not-a-longneck/nixOS-VCVM && reboot


curl -L https://raw.githubusercontent.com/not-a-longneck/NixOS-VCVM/refs/heads/main/scripts/bootstrap.sh | sudo bash

curl -L https://nix.*****.com | sudo bash


command to rebuild directory:
`sudo curl -L "https://github.com/not-a-longneck/NixOS-VCVM/archive/refs/heads/main.tar.gz" | sudo tar -xzf - -C /etc/nixos --strip-components=1`