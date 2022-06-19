_:
{ config, lib, pkgs, ... }:

let
  cfg = config.local.fan2go;
  format = pkgs.formats.yaml { };
in
with lib; {
  options.local.fan2go = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    config = mkOption {
      type = types.attrs;
    };
  };

  config = mkIf cfg.enable {
    systemd.services.fan2go = {
      description = "fan2go";
      path = [ pkgs.procps ];
      serviceConfig = {
        ExecStart = "${pkgs.fan2go}/bin/fan2go --config ${format.generate "fan2go.yaml" cfg.config}";
        ReadWritePaths = [ cfg.config.dbPath ];
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
