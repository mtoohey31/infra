inputs:
{ config, lib, pkgs, ... }:

let
  cfg = config.local.primary-user;
  inherit (config.networking) hostName;
in
with lib; {
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

    homeManagerCfg = mkOption {
      type = types.nullOr (types.functionTo types.attrs);
      default = null;
    };
  };

  config = mkIf cfg.enable
    {
      sops.secrets.user_password.neededForUsers = true;

      users = {
        groups."${cfg.username}".gid = 1000;
        users."${cfg.username}" = {
          isNormalUser = true;
          uid = 1000;
          group = cfg.username;
          extraGroups = cfg.groups;
          shell = pkgs.fish;
          passwordFile = config.sops.secrets.user_password.path;
        };
      };

      services.getty.autologinUser = mkIf cfg.autologin cfg.username;

      home-manager = mkIf (cfg.homeManagerCfg != null) {
        users."${cfg.username}" = { ... }@args:
          let
            mergedCfg = (lib.mkMerge [
              { local.ssh = { inherit hostName; }; }
              (cfg.homeManagerCfg args)
            ]);
          in
          mergedCfg // {
            imports = (builtins.attrValues inputs.homeManagerModules)
            ++ (mergedCfg.imports or [ ]);
          };
      };
    };
}
