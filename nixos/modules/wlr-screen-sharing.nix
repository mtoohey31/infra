_:
{ config, lib, ... }:

let cfg = config.local.wlr-screen-sharing;
in
with lib; {
  options.local.wlr-screen-sharing.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };
  };
}
