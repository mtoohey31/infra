inputs:
{ config, pkgs, ... }:

{
  local = {
    arch-emu.aarch64.enable = true;
    bluetooth.enable = true;
    gaming.enable = true;
    harpoond.enable = true;
    opengl.enable = true;
    primary-user = {
      autologin = true;
      homeManagerCfg = { config, ... }: {
        local = {
          devel.enable = true;
          gui.enable = true;
          music.enable = true;
          wm.enable = true;
        };

        home.packages = with pkgs; [
          himalaya # TODO: add configuration
          gimp
          bitwarden-cli
          bitwarden
          signal-desktop
          obs-studio
          bitwig-studio
        ];

        xdg = {
          desktopEntries.discord = {
            name = "Discord";
            exec = "brave --profile-directory=Profile\\s2 --app=https://discord.com/app";
            terminal = false;
          };
          mimeApps = {
            enable = true;
            associations.added."image/png" = "gimp.desktop";
          };
        };

        programs.fish = rec {
          shellAbbrs.hi = "himalaya";
          shellAliases = shellAbbrs;
        };

        wayland.windowManager.sway.config.keybindings =
          let modifier = config.wayland.windowManager.sway.config.modifier; in
          {
            "${modifier}+z" = "exec ${pkgs.writeShellScript "vm-focus" ''
                      set -e
                      ddcutil setvcp 60 0x0F
                      virsh attach-device win11-dgpu ${./input-harpoon.xml}
                      virsh attach-device win11-dgpu ${./input-zen.xml}
                      swaymsg output "'Acer Technologies XV340CK P THQAA0013P00'" disable
                    ''}";
            "${modifier}+x" = "exec ${pkgs.writeShellScript "vm-unfocus" ''
                      set -e
                      swaymsg output "'Acer Technologies XV340CK P THQAA0013P00'" enable
                      ddcutil setvcp 60 0x11
                      virsh detach-device win11-dgpu ${./input-harpoon.xml}
                      virsh detach-device win11-dgpu ${./input-zen.xml}
                    ''}";
          };
      };
      groups = [ "wheel" "video" "docker" ];
    };
    sops.enable = true;
    sound.enable = true;
    virtualisation = {
      enable = true;
      # TODO: add hooks to isolate host cpus to 0-3 (see: https://github.com/mtoohey31/dotfiles/blob/main/.scripts/setup/stow/libvirt/etc/libvirt/hooks/qemu)
      # as well as a hook for running `supergfxctl -m vfio` for the dgpu vm
      vms = {
        win11 = ./win11.xml;
        win11-dgpu = builtins.toPath (builtins.toFile "win11-dgpu.xml" ((builtins.readFile ./win11-dgpu-head.xml) + ''
              <qemu:arg value="file=${./SSDT1.dat}"/>
            </qemu:commandline>
          </domain>
        ''));
      };
    };
    wlr-screen-sharing.enable = true;
  };

  services.kmonad = {
    enable = true;
    keyboards.default = {
      device = "/dev/input/by-id/usb-ASUSTeK_Computer_Inc._N-KEY_Device-if02-event-kbd";
      fallthrough = true;
      config = builtins.readFile ./default.kbd;
    };
  };
  systemd.services.kmonad-default = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  imports = with inputs.cogitri.nixosModules; [
    asusd
    supergfxd

    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.asus-zephyrus-ga401
  ];

  virtualisation.docker.enable = true;

  services.printing.enable = true;

  networking.wireless.iwd.enable = true;

  programs.light.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.systemPackages = [ pkgs.nvtop ];

  services.supergfxd = {
    enable = true;
    gfx-mode = "Integrated";
    gfx-vfio-enable = true;
  };
  services.power-profiles-daemon.enable = true;
  systemd.services.power-profiles-daemon = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };
  services.asusd.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_5_17;
  boot.kernelPatches = let inherit (inputs) g14-patches; in
    map (patch: { inherit patch; }) [
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0004-5.15+--more-uarches-for-kernel.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0005-lru-multi-generational.patch"

      "${g14-patches}/sys-kernel_arch-sources-g14_files-0043-ALSA-hda-realtek-Fix-speakers-not-working-on-Asus-Fl.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0047-asus-nb-wmi-Add-tablet_mode_sw-lid-flip.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0048-asus-nb-wmi-fix-tablet_mode_sw_int.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0049-ALSA-hda-realtek-Add-quirk-for-ASUS-M16-GU603H.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-0050-asus-flow-x13-support_sw_tablet_mode.patch"

      # mediatek mt7921 bt/wifi patches
      "${g14-patches}/sys-kernel_arch-sources-g14_files-8017-mt76-mt7921-enable-VO-tx-aggregation.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-8026-cfg80211-dont-WARN-if-a-self-managed-device.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-8050-r8152-fix-spurious-wakeups-from-s0i3.patch"

      # squashed s0ix enablement through
      "${g14-patches}/sys-kernel_arch-sources-g14_files-9001-v5.16.11-s0ix-patch-2022-02-23.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-9004-HID-asus-Reduce-object-size-by-consolidating-calls.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-9005-acpi-battery-Always-read-fresh-battery-state-on-update.patch"

      "${g14-patches}/sys-kernel_arch-sources-g14_files-9006-amd-c3-entry.patch"

      "${g14-patches}/sys-kernel_arch-sources-g14_files-9010-ACPI-PM-s2idle-Don-t-report-missing-devices-as-faili.patch"
      "${g14-patches}/sys-kernel_arch-sources-g14_files-9012-Improve-usability-for-amd-pstate.patch"
    ];

  services.udev.extraRules = builtins.readFile "${pkgs.stdenv.mkDerivation rec {
    pname = "arctis-9-udev-rules";
    version = "0.1.0";
    nativeBuildInputs = [ pkgs.headsetcontrol ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p "$out/share/headsetcontrol"
      RULES="$(headsetcontrol -u | grep -A1 "SteelSeries Arctis 9")"
      if test -z "$RULES"; then
        exit 1
      fi
      echo "$RULES" > "$out/share/headsetcontrol/99-arctis-9.rules"
    '';
  }}/share/headsetcontrol/99-arctis-9.rules";

  # for quiet startup
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "udev.log_level=3" ];

  # TODO: figure out how to set this in the homeManager wm role, since swaylock needs this
  security.pam.services.swaylock = { };
}
