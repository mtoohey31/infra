{ config, pkgs, stdenv, ... }:

let
  lib = import ../../lib;
  asusctl_pr_tar = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/a4a81b6f6c27e5a964faea25b7b5cbe611f98691.tar.gz";
    sha256 = "1z9j1hp69i3j8b3v9val8v4sxy7hzdggg2a2rfvjp7aq6h1bpfax";
  };

  prime-run = pkgs.writeShellScriptBin "prime-run" ''
    __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
  '';
in {
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
        "${asusctl_pr_tar}/pkgs/tools/misc/supergfxctl/default.nix" { };
    })
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    prime = {
      offload.enable = true;
      amdgpuBusId = "PCI:4:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.systemPackages = with pkgs; [ nvtop prime-run ];

  services.supergfxctl = {
    enable = true;
    gfx-mode = "Integrated";
    gfx-vfio-enable = true;
  };
  services.asusctl.enable = true;

  users = lib.mkPrimaryUser { username = "mtoohey"; } pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg {
    user = "dailyDriver";
    username = "mtoohey";
  };

  services.getty.autologinUser = "mtoohey";
}
