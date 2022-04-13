{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    himalaya # TODO: add configuration
    pandoc # TODO: add configuration with defaults
    texlive.combined.scheme-medium
    gimp
    discord
    bitwarden
    bitwarden-cli
    signal-desktop
    obs-studio
  ];

  xdg.mimeApps.associations.added."image/png" = "gimp.desktop";

  programs.fish = rec {
    shellAbbrs.hi = "himalaya";
    shellAliases = shellAbbrs;
  };
}
