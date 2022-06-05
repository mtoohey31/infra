.PHONY: default install user nixos install-nixos darwin install-darwin droid cloudberry-image format format-check deadnix-check

NIX_CMD = nix --extra-experimental-features nix-command --extra-experimental-features flakes

ifeq ($(shell uname),Darwin)
default: darwin
install: install-darwin
else ifeq ($(shell whoami),nix-on-droid)
default: droid
else
default: nixos
install: install-nixos
endif

ifeq (${TERM},xterm-kitty)
KITTY_TERMFIX = TERM=xterm-256color 
endif

ci: format-check deadnix-check

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

droid:
	test -n "$$INFRA_DEVICE" || exit 1
	nix-on-droid switch --flake ".#$$INFRA_DEVICE"

cloudberry-image:
	$(NIX_CMD) build .#nixosImages.cloudberry

install-cloudberry-image:
	test -n "$$INFRA_OF" || exit 1
	$(NIX_CMD) build .#nixosImages.cloudberry
	export TMP="$$(mktemp)" && export MOUNT="$$(mktemp -d)" && cp result/sd-image/cloudberry-*.img "$$TMP" && \
		export OFFSET="$$(partx "$$TMP" | tail -n1 | cut -d' ' -f3)" && \
		export USERNAME="$$(nix eval --raw --file secrets.nix systems.cloudberry.username)" && \
		sudo mount -o loop,offset="$$(("$$OFFSET"*512))" "$$TMP" "$$MOUNT" && sudo mkdir -p "$$MOUNT/home/$$USERNAME/.ssh" && \
		sops -d --extract '["user_ssh_private_key"]' nixos/systems/cloudberry/secrets.yaml | sudo tee "$$MOUNT/home/$$USERNAME/.ssh/id_ed25519" >/dev/null && \
		sudo umount "$$MOUNT" && sudo dd if="$$TMP" of="$$INFRA_OF" status=progress && sudo rm -rf "$$TMP" "$$MOUNT"

format:
	nixpkgs-fmt .

format-check:
	nixpkgs-fmt --check .

deadnix-check:
	deadnix --fail $$(find -name '*.nix' -not -name 'hardware-configuration.nix')
