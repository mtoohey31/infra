_:
{ config, lib, pkgs, ... }:

# TODO: ~~find out where virt-manager configs are stored~~
# it's ~/.config/glib-2.0/settings/keyfile, but other things use that file too,
# so I'm not sure how I can set make it read only with out breaking other stuff

let
  cfg = config.local.virtualisation;
  inherit (config.local.primary-user) username;
in
with lib; {
  options.local.virtualisation = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    vms = mkOption {
      type = types.attrsOf types.path;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ddcutil virt-manager ];

    # needed for ddcutil
    hardware.i2c.enable = true;

    users.users."${config.local.primary-user.username}".extraGroups = [ "i2c" "kvm" "libvirt" ];
    users.groups.kvm = { };
    users.groups.libvirt = { };

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        ovmf.enable = true;
        verbatimConfig = ''
          user = "${username}"
        '';
      };
    };

    system.activationScripts.libvirt-vms.text = lib.strings.concatStringsSep "\n"
      (lib.attrsets.mapAttrsToList
        (name: path: "ln -Tfs ${path} /var/lib/libvirt/qemu/${name}.xml")
        cfg.vms);
  };
}
