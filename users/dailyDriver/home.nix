{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    himalaya # TODO: add configuration
    pandoc # TODO: add configuration with defaults
    gimp
    discord
    bitwarden
    bitwarden-cli
  ];
}
