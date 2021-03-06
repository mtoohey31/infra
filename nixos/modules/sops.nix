_:
{ config, lib, ... }:

let
  cfg = config.local.sops;
  inherit (config.networking) hostName;
  inherit (config.local.primary-user) username;
in
with lib; {
  options.local.sops.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    assertions = [
      { assertion = config.local.primary-user.enable; }
    ];

    sops.defaultSopsFile = ../systems + "/${hostName}/secrets.yaml";
    sops.age.sshKeyPaths = [
      (config.users.users.${username}.home + "/.ssh/id_ed25519")
    ];
  };
}
