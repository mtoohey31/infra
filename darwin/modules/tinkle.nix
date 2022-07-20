_:
{ config, lib, pkgs, ... }:

let
  cfg = config.local.tinkle;
in
with lib; {
  options.local.tinkle.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tinkle ];

    system.activationScripts.userDefaults.text = ''
      defaults write org.pqrs.Tinkle effect shockwaveGray
    '';
  };
}
