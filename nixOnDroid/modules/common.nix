inputs:
{ config, lib, pkgs, ... }:

let cfg = config.local.common;
in
with lib; {
  options.local.common.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = mkIf cfg.enable {
    nix = {
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = true
      '';
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    environment.packages = [ pkgs.openssh ];

    # TODO: set up gc
    # nix.gc = {
    #   automatic = true;
    #   options = "--delete-older-than 14d";
    # };
  };
}
