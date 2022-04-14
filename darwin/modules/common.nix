{ pkgs, ... }:

{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };

  services.nix-daemon.enable = true;
}
