{ lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) lib.allowedUnfree;
  nixpkgs.config.permittedInsecurePackages = lib.allowedInsecure;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
    '';
  };

  # TODO: figure out how to set password securely in configuration, then enable this
  # users.mutableUsers = false;

  boot.loader.systemd-boot.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  system.stateVersion = "21.11";

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
}
