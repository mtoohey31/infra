{ config, pkgs, stdenv, ... }:

let lib = import ../../lib;
in {
  # TODO: add required groups
  users = lib.mkPrimaryUser { username = "mtoohey"; } pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg {
    user = "dailyDriver";
    username = "mtoohey";
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "nvidia" ];
  # hardware.nvidia.modesetting.enable
  environment.systemPackages = with pkgs; [ "nvidia" ];

  services.getty.autologinUser = "mtoohey";
}
