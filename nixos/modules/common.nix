inputs:
{ config, lib, ... }:

let cfg = config.local.common; in
with lib; {
  options.local.common.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = mkIf cfg.enable {
    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = true
      '';
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };

    users.mutableUsers = false;

    time.timeZone = "America/Toronto";
    i18n.defaultLocale = "en_CA.UTF-8";

    system.stateVersion = "21.11";

    sops.secrets.root_password.neededForUsers = true;
    users.users.root.passwordFile = config.sops.secrets.root_password.path;
  };
}
