_:
{ config, lib, ... }:

let cfg = config.local.sops; in
with lib; {
  options.local.sops.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../secrets.yaml;
      age.sshKeyPaths = [
        (config.home.homeDirectory + "/.ssh/id_ed25519")
      ];
    };
  };
}
