.PHONY: system user install update

system:
	sudo nixos-rebuild switch --flake .#
	
user:
	nix build .#homeManagerConfigurations."$$(whoami)-${user}-$$(uname -m)-$$(uname | tr '[:upper:]' '[:lower:]')".activationPackage
	result/activate
	
install:
	nixos-install --flake .#
	
update:
	nix flake update
