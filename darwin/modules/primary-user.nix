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

    username = mkOption {
      type = types.str;
      default = config.local.secrets.systems.${hostName}.username;
    };

    homeManagerCfg = mkOption {
      type = types.nullOr (types.functionTo types.attrs);
      default = null;
    };
  };

  config = mkIf cfg.enable
    {
      users = {
        users.${cfg.username} = {
          home = "/Users/${cfg.username}";
          createHome = true;
          shell = pkgs.fish;
        };
      };

      home-manager = mkIf (cfg.homeManagerCfg != null) {
        users.${cfg.username} = { ... }@args: {
          imports = builtins.attrValues inputs.homeManagerModules;
        } // (cfg.homeManagerCfg args);
      };

      system.activationScripts.users.text = ''
        if [ "$(dscl . -read /Users/${cfg.username} UserShell)" != 'UserShell: ${pkgs.fish}/bin/fish' ]; then
            dscl . -create '/Users/${cfg.username}' UserShell '${pkgs.fish}/bin/fish'
        fi
      '';
    };
}
