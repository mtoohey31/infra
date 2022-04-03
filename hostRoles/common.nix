{ pkgs, lib, ... }: {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      "steam"
      "steam-original"
      "cudatoolkit"
    ];

  boot.loader.systemd-boot.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # TODO: tweak ssh settings to make things more secure
  services.openssh.enable = true;
  system.stateVersion = "21.11";
}
