{ config, lib, ... }:

let cfg = config.local.opengl;
in
with lib; {
  options.local.opengl.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport32Bit = true;
    };
  };
}
