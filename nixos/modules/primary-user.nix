{ config, lib, pkgs, flake-inputs, ... }:

let
  cfg = config.local.primary-user;
  inherit (config.networking) hostName;
in
with lib; {
  imports = [ flake-inputs.home-manager.nixosModule ];

  options.local.primary-user = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    autologin = mkOption {
      type = types.bool;
      default = false;
    };

    groups = mkOption {
      type = types.listOf types.str;
      default = [ "wheel" ];
    };

    username = mkOption {
      type = types.str;
      default = config.local.secrets.systems."${hostName}".username;
    };

    homeManagerUser = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable
    {
      users = {
        groups."${cfg.username}".gid = 1000;
        users."${cfg.username}" = {
          isNormalUser = true;
          uid = 1000;
          group = cfg.username;
          extraGroups = cfg.groups;
          shell = pkgs.fish;
        };
      };

      services.getty.autologinUser = mkIf cfg.autologin cfg.username;

      home-manager = mkIf (cfg.homeManagerUser != null) {
        extraSpecialArgs = {
          inherit flake-inputs;
          inherit (config.networking) hostName;
        };
        useUserPackages = true;
        useGlobalPkgs = true;
        users."${cfg.username}" = lib.mkHomeCfg { user = cfg.homeManagerUser; };
      };
    };
}
