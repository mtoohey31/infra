{ config, lib, ... }:

let cfg = config.local.bluetooth;
in
with lib; {
  options.local.bluetooth.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
