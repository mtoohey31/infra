inputs:
{ config, lib, ... }:

let cfg = config.local.common;
in
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

    services.nix-daemon.enable = true;

    programs.fish.enable = true;

    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        _HIHideMenuBar = true;
      };
      dock = {
        autohide = true;
        autohide-delay = "0.0";
        autohide-time-modifier = "0.25";
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
      };
      loginwindow.GuestEnabled = false;
      trackpad = {
        Clicking = true;
        Dragging = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
