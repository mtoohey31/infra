_:
{ config, lib, ... }:

let
  cfg = config.local.ssh;
  inherit (config.local.secrets) systems;
in
with lib; {
  options.local.ssh = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    hostName = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    home.file.".ssh/id_ed25519.pub".text = systems.${cfg.hostName}.user_ssh_public_key + "\n";

    programs.ssh = {
      enable = true;
      matchBlocks = listToAttrs
        (map
          (hostName: {
            name = hostName;
            value = let value = systems.${hostName}; in
              {
                hostname = value.wg_ip;
                port = value.ssh_port;
                user = value.username;
              };
          })
          (filter
            (hostName:
              let v = systems.${hostName}; in
              (hasAttr "ssh_port" v) && (hasAttr "username" v) && (hasAttr "wg_ip" v))
            (attrNames systems)));
      userKnownHostsFile = "~/.ssh/known_hosts ${config.home.homeDirectory}/.ssh/preset_known_hosts";
    };

    # TODO: fix this, it's broken because it doesn't specify port numbers, and
    # it uses the raw public key instead of the public key fingerprint
    home.file.".ssh/preset_known_hosts".text =
      strings.concatMapStringsSep "\n"
        (hostName:
          "${systems.${hostName}.wg_ip} ${systems.${hostName}.system_ssh_public_key}"
        )
        (filter (hostName: hasAttr "system_ssh_public_key" systems.${hostName})
          (attrNames systems));
  };
}
