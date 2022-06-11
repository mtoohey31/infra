inputs:
{ config, lib, pkgs, ... }:

let
  cfg = config.local.common;
  inherit (config.networking) hostName;
in
with lib; {
  options.local.common.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = mkIf cfg.enable {
    nix = {
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = true
      '';
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    users.mutableUsers = false;

    time.timeZone = "America/Toronto";
    i18n.defaultLocale = "en_CA.UTF-8";

    system.stateVersion = "21.11";

    sops.secrets.root_password = {
      neededForUsers = true;
      sopsFile = ../systems + "/${hostName}/secrets.yaml";
    };
    users.users.root.passwordFile = config.sops.secrets.root_password.path;

    nix.gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  }
  ;
}
