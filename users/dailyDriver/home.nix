{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    himalaya # TODO: add configuration
    pandoc # TODO: add configuration with defaults
    texlive.combined.scheme-medium
    gimp
    bitwarden
    bitwarden-cli
    signal-desktop
    obs-studio
  ];

  xdg.desktopEntries.discord = pkgs.lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    name = "Discord";
    exec = "brave --profile-directory=\"Profile 2\" --app=https://discord.com/app";
    terminal = false;
  };
  xdg.mimeApps.associations.added."image/png" = "gimp.desktop";

  programs.fish = rec {
    shellAbbrs.hi = "himalaya";
    shellAliases = shellAbbrs;
  };
}
