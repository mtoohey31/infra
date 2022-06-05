inputs:
{ config, lib, pkgs, ... }:

let cfg = config.local.primary-user; in
with lib; {
  options.local.primary-user = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    hostName = mkOption {
      type = types.str;
    };

    homeManagerCfg = mkOption {
      type = types.nullOr (types.functionTo types.attrs);
      default = null;
    };
  };

  config = mkIf cfg.enable
    {
      user.shell = "${pkgs.fish}/bin/fish";

      home-manager = mkIf (cfg.homeManagerCfg != null) {
        config = { ... }@args:
          let mergedCfg = (lib.mkMerge [
            { local.ssh = { inherit (cfg) hostName; }; }
            (cfg.homeManagerCfg args)
          ]); in
          mergedCfg // {
            imports = (builtins.attrValues inputs.homeManagerModules)
            ++ (mergedCfg.imports or [ ]);
          };
      };
    };
}
