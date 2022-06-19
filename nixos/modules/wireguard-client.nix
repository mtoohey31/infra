_:
{ config, lib, ... }:

let
  cfg = config.local.wireguard-client;
  hostName = config.networking.hostName;
in
with lib; {
  options.local.wireguard-client = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    keepAlive = mkOption {
      type = types.bool;
      default = true;
    };

    routeAll = mkOption {
      type = types.bool;
      default = true;
    };

    address = mkOption {
      type = types.str;
      default = config.local.secrets.systems."${hostName}".wg_ip + "/24";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.wg_private_key = { };

    networking.wg-quick.interfaces.wg0 = let inherit (config.local.secrets.systems) vps; in
      {
        address = [ cfg.address ];
        dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        listenPort = vps.wg_port;
        peers = [
          ({
            allowedIPs = if cfg.routeAll then [ "0.0.0.0/0" "::/0" ] else [ "10.0.0.0/8" ];

            endpoint = "${vps.public_ip}:${builtins.toString vps.wg_port}";
            publicKey = vps.wg_public_key;
          } // (lib.optionalAttrs cfg.keepAlive {
            persistentKeepalive = 25;
          }))
        ];
        privateKeyFile = config.sops.secrets.wg_private_key.path;
      };
  };
}
