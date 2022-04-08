{ config, pkgs, stdenv, ... }:

let
  lib = import ../../lib;
  asusctl_pr_tar = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/a4a81b6f6c27e5a964faea25b7b5cbe611f98691.tar.gz";
    sha256 = "1z9j1hp69i3j8b3v9val8v4sxy7hzdggg2a2rfvjp7aq6h1bpfax";
  };
  g14_patches = fetchGit {
    url = "https://gitlab.com/dragonn/linux-g14";
    ref = "5.17";
    rev = "ed8cf277690895c5b2aa19a0c89b397b5cd2073d";
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
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.systemPackages = [ pkgs.nvtop ];

  services.supergfxctl = {
    enable = true;
    gfx-mode = "Integrated";
    gfx-vfio-enable = true;
  };
  services.power-profiles-daemon.enable = true;
  systemd.services.power-profiles-daemon = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };
  services.asusctl.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.kernelPatches = map (patch: { inherit patch; }) [
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0004-5.15+--more-uarches-for-kernel.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0005-lru-multi-generational.patch"

    "${g14_patches}/sys-kernel_arch-sources-g14_files-0043-ALSA-hda-realtek-Fix-speakers-not-working-on-Asus-Fl.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0047-asus-nb-wmi-Add-tablet_mode_sw-lid-flip.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0048-asus-nb-wmi-fix-tablet_mode_sw_int.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0049-ALSA-hda-realtek-Add-quirk-for-ASUS-M16-GU603H.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-0050-asus-flow-x13-support_sw_tablet_mode.patch"

    # mediatek mt7921 bt/wifi patches
    "${g14_patches}/sys-kernel_arch-sources-g14_files-8017-mt76-mt7921-enable-VO-tx-aggregation.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-8018-mt76-mt7921e-fix-possible-probe-failure-after-reboot.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-8026-cfg80211-dont-WARN-if-a-self-managed-device.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-8050-r8152-fix-spurious-wakeups-from-s0i3.patch"

    # squashed s0ix enablement through
    "${g14_patches}/sys-kernel_arch-sources-g14_files-9001-v5.16.11-s0ix-patch-2022-02-23.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-9004-HID-asus-Reduce-object-size-by-consolidating-calls.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-9005-acpi-battery-Always-read-fresh-battery-state-on-update.patch"

    "${g14_patches}/sys-kernel_arch-sources-g14_files-9006-amd-c3-entry.patch"

    "${g14_patches}/sys-kernel_arch-sources-g14_files-9010-ACPI-PM-s2idle-Don-t-report-missing-devices-as-faili.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-9011-cpufreq-CPPC-Fix-performance-frequency-conversion.patch"
    "${g14_patches}/sys-kernel_arch-sources-g14_files-9012-Improve-usability-for-amd-pstate.patch"
  ];

  # for quiet startup
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "udev.log_level=3" ];

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
