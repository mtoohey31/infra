_:
{ config, lib, ... }:

let
  cfg = config.local.ssh;
  inherit (config.networking) hostName;
  inherit (config.local.primary-user) username;
  inherit (config.local.secrets) systems;
in
with lib; {
  options.local.ssh = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    authorizedHosts = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    services.openssh.enable = true;

    # TODO: uncomment this once everything is set up with the key sharing system
    # services.openssh.passwordAuthentication = false;

    services.openssh.ports = [ systems."${hostName}".ssh_port ];
    services.openssh.hostKeys = [ ];
    # TODO: once mobile devices are hooked into the key sharing system, add
    # build outputs for their respective ssh config and known hosts files
    services.openssh.passwordAuthentication = false;
    environment.etc = {
      "ssh/ssh_host_ed25519_key.pub".text = systems."${hostName}".system_ssh_public_key;
      "ssh/ssh_host_ed25519_key".source = config.sops.secrets.system_ssh_private_key.path;
    };
    sops.secrets.system_ssh_private_key.sopsFile = ../systems + "/${hostName}/secrets.yaml";

    users.users."${username}".openssh.authorizedKeys.keys = map (hostName: systems."${hostName}".user_ssh_public_key) cfg.authorizedHosts;
  };
}
