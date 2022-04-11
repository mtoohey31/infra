.PHONY: system user install update format

system:
	sudo nixos-rebuild switch --flake .#
	
user:
	nix build .#homeManagerConfigurations."$$(whoami)-$$INFRA_USER-$$(uname -m)-$$(uname | tr '[:upper:]' '[:lower:]')".activationPackage
	result/activate
	
install:
	nixos-install --flake .#
	
update:
	nix flake update
	
format:
	nixpkgs-fmt .
