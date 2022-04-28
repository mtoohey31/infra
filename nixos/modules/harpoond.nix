{ config, lib, pkgs, ... }:

let cfg = config.local.harpoond;
in
with lib; {
  options.local.harpoond.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.harpoond ];

    services.udev.extraRules = builtins.readFile
      "${pkgs.harpoond}/lib/udev/rules.d/99-harpoond.rules";
    systemd.services.harpoond = {
      enable = true;
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.harpoond}/bin/harpoond";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
