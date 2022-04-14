.PHONY: system user install update develop format

system:
	sudo nixos-rebuild switch --flake .#
	
user:
	nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#homeManagerConfigurations."$$(whoami)-$$INFRA_USER-$$(uname -m)-$$(uname | tr '[:upper:]' '[:lower:]')".activationPackage
	result/activate
	
install:
	nixos-install --flake .#
	
update:
	nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update

develop:
	nix --extra-experimental-features nix-command --extra-experimental-features flakes develop
	
format:
	nixpkgs-fmt .
