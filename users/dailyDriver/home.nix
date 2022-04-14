{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    himalaya # TODO: add configuration
    gimp
    bitwarden
    bitwarden-cli
    signal-desktop
    obs-studio
  ];

  xdg = pkgs.lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    desktopEntries.discord = {
      name = "Discord";
      exec = "brave --profile-directory=\"Profile 2\" --app=https://discord.com/app";
      terminal = false;
    };
    mimeApps = {
      enable = true;
      associations.added."image/png" = "gimp.desktop";
    };
  };

  programs.fish = rec {
    shellAbbrs.hi = "himalaya";
    shellAliases = shellAbbrs;
  };
}
