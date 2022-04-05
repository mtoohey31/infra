{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.taskmatter ];

  programs.fish = rec {
    shellAbbrs.tm = "taskmatter";
    shellAliases = shellAbbrs;
  };
}
