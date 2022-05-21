.PHONY: default install user nixos install-nixos darwin install-darwin cloudberry-image update develop format

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
	nixos-rebuild switch --use-remote-sudo --flake .#

# TODO: test this with an iso
install-nixos:
	nixos-install --flake .#nixosConfigurations."$${INFRA_SYSTEM:-$$HOSTNAME}"	

darwin:
	$(KITTY_TERMFIX)darwin-rebuild switch --flake .#

install-darwin:
	$(KITTY_TERMFIX)$(NIX_CMD) build .#darwinConfigurations."$${INFRA_SYSTEM:-$$HOSTNAME}".system
	./result/sw/bin/darwin-rebuild switch --flake .#"$${INFRA_SYSTEM:-$$HOSTNAME}"

cloudberry-image:
	$(NIX_CMD) build .#nixosImages.cloudberry

install-cloudberry-image:
	test -n "$$INFRA_OF" || exit 1
	$(NIX_CMD) build .#nixosImages.cloudberry
	export TMP="$$(mktemp)" && unzstd --force result/sd-image/*.img.zst -o "$$TMP" && \
		sudo dd if="$$TMP" of="$$INFRA_OF" && rm -f "$$TMP"

update:
	$(NIX_CMD) flake update

develop:
	$(NIX_CMD) develop

check:
	$(NIX_CMD) flake check

format:
	nixpkgs-fmt .
