{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    # TODO: taskmatter
    himalaya # TODO: add configuration
    pandoc # TODO: add configuration with defaults
    gimp
    discord
    bitwarden
    bitwarden-cli
  ];
}
