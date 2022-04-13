{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    plover.dev
    firefox
  ];
}
