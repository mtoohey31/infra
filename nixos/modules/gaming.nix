_:
{ config, lib, pkgs, ... }:

let cfg = config.local.gaming;
in
with lib; {
  options.local.gaming.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
      rpcs3
      osu-lazer
      wine
      legendary-gl
    ];
  };
}
