_:
{ config, lib, ... }:

let
  cfg = config.local.fileshelter;
  inherit (config.networking) hostName;
in
with lib; {
  options.local.fileshelter.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    sops.secrets.cloudflare_config = {
      owner = config.users.users.caddy.name;
      inherit (config.users.users.caddy) group;
      sopsFile = ../systems + "/${hostName}/secrets.yaml";
    };
    services.caddy = {
      enable = true;
      package = pkgs.caddy-cloudflare;
      acmeCA = null;
      configFile = config.sops.secrets.cloudflare_config.path;
    };
    systemd.services.caddy.serviceConfig.AmbientCapabilities = "CAP_NET_BIND_SERVICE";

    users.groups.fileshelter = { };
    users.users.fileshelter = {
      group = "fileshelter";
      uid = 357;
      createHome = true;
      home = "/var/fileshelter";
    };
    systemd.services.fileshelter = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = [
          ""
          # toFile doesn't work because it doesn't allow references to derivations
          "${pkgs.fileshelter}/bin/fileshelter ${pkgs.runCommand
        "fileshelter.conf" { nativeBuildInputs = [ pkgs.fileshelter ]; } ''
          cat "${pkgs.fileshelter.src}/conf/fileshelter.conf" | \
            sed 's/max-file-size = 100;/max-file-size = 10000;/' | \
            sed 's,/usr,${pkgs.fileshelter},' > "$out"
        ''}"
        ];
        User = "fileshelter";
        Group = "fileshelter";
      };
    };
  };
}
