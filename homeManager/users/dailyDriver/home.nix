{ lib, pkgs, ... }:

{
  # TODO: figure out how to pass flake lib to this point
  local = {
    devel.enable = true;
    music.enable = true;
    gui.enable = true;
    wm.enable = !pkgs.stdenv.hostPlatform.isDarwin;
  };

  home.packages = with pkgs; [
    himalaya # TODO: add configuration
    gimp
    bitwarden-cli
  ] ++ pkgs.lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
    # TODO: get these working on darwin
    bitwarden
    signal-desktop
    obs-studio
    bitwig-studio
  ];

  xdg = pkgs.lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    desktopEntries.discord = {
      name = "Discord";
      exec = "brave --profile-directory=Profile\\s2 --app=https://discord.com/app";
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
