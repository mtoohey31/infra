{ config, lib, pkgs, flake-inputs, ... }:

{
  imports = [ flake-inputs.home-manager.darwinModule ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) lib.allowedUnfree;
  nixpkgs.config.permittedInsecurePackages = lib.allowedInsecure;

  home-manager = {
    extraSpecialArgs = {
      inherit flake-inputs;
      inherit (config.networking) hostName;
    };
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
}
