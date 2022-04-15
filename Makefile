.PHONY: default user nixos darwin install update develop format

NIX_CMD = nix --extra-experimental-features nix-command --extra-experimental-features flakes
UNAME := $(shell uname)

ifeq ($(UNAME),Darwin)
default: darwin
install: install-darwin
else
default: nixos
install: install-nixos
endif

ifeq (${TERM},xterm-kitty)
KITTY_TERMFIX = TERM=xterm-256color 
endif

user:
	$(NIX_CMD) build .#homeManagerConfigurations."$$(whoami)-$$INFRA_USER-$$(uname -m)-$$(uname | tr '[:upper:]' '[:lower:]')".activationPackage
	result/activate

nixos:
	sudo nixos-rebuild switch --flake .#

# TODO: test this with an iso
install-nixos:
	nixos-install --flake .#nixosConfigurations."$${INFRA_SYSTEM:-$$HOSTNAME}"	

darwin:
	$(KITTY_TERMFIX)darwin-rebuild switch --flake .#

install-darwin:
	$(KITTY_TERMFIX)$(NIX_CMD) build .#darwinConfigurations."$${INFRA_SYSTEM:-$$HOSTNAME}".system
	./result/sw/bin/darwin-rebuild switch --flake .#"$${INFRA_SYSTEM:-$$HOSTNAME}"
	
update:
	$(NIX_CMD) flake update

develop:
	$(NIX_CMD) develop
	
format:
	nixpkgs-fmt .
