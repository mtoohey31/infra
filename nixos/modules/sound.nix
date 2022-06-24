_:
{ config, lib, ... }:

let cfg = config.local.sound; in
with lib; {
  options.local.sound.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };
}
