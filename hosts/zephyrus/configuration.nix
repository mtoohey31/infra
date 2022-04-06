{ config, pkgs, stdenv, ... }:

# TODO: disable verbose startup messages so I don't scare people in class
# TODO: fix keyboard flashing during sleep

let
  lib = import ../../lib;
  asusctl_pr_tar = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/a4a81b6f6c27e5a964faea25b7b5cbe611f98691.tar.gz";
    sha256 = "1z9j1hp69i3j8b3v9val8v4sxy7hzdggg2a2rfvjp7aq6h1bpfax";
  };
in
{
  imports = [
    "${asusctl_pr_tar}/nixos/modules/services/misc/asusctl.nix"
    "${asusctl_pr_tar}/nixos/modules/services/misc/supergfxctl.nix"
  ];

  nixpkgs.overlays = [
    (self: super: {
      asusctl =
        pkgs.callPackage "${asusctl_pr_tar}/pkgs/tools/misc/asusctl/default.nix"
          { };
      supergfxctl = pkgs.callPackage
        "${asusctl_pr_tar}/pkgs/tools/misc/supergfxctl/default.nix"
        { };
    })
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.systemPackages = [ pkgs.nvtop ];

  services.supergfxctl = {
    enable = true;
    gfx-mode = "Integrated";
    gfx-vfio-enable = true;
  };
  services.asusctl.enable = true;

  # TODO: add kernel patches to get asusctl profiles working as per https://gitlab.com/asus-linux/asusctl/-/issues/134
  boot.kernelPackages = pkgs.linuxPackages_latest;

  programs.light.enable = true;
  users = lib.mkPrimaryUser
    {
      username = "mtoohey";
      groups = [ "wheel" "video" "docker" ];
    }
    pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg "dailyDriver" pkgs;

  services.getty.autologinUser = "mtoohey";
}
