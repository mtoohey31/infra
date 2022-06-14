# [mtoohey31/infra](https://github.com/mtoohey31/infra)

My personal infrastructure, as code in the form of a Nix flake.

## Environments

This flake uses the following inputs to configure a variety of environments:

- [Home Manager](https://github.com/nix-community/home-manager): for managing dotfiles inside the other environments.
- [NixOS](https://nixos.org): for the machines I can run Linux on!
- [nix-darwin](https://github.com/LnL7/nix-darwin): for the machines I have to run MacOS on...
- [Nix-on-Droid](https://github.com/t184256/nix-on-droid): for Android devices.

## Secrets

Secrets are handled with a combination of the following two tools:

- [sops-nix](https://github.com/Mic92/sops-nix): for secrets that are specific to individual systems and _don't_ need to be evaluated at build time.
- [git-crypt-agessh](https://github.com/mtoohey31/git-crypt-agessh): for shared "security-by-obscurity"-type secrets that _do_ need to be evaluated at build time (and can safely be visible in the Nix store).
