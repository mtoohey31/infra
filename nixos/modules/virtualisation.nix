# TODO: ~~find out where virt-manager configs are stored~~
# it's ~/.config/glib-2.0/settings/keyfile, but other things use that file too,
# so I'm not sure how I can set make it read only with out breaking other stuff

{ config, lib, pkgs, ... }:

let cfg = config.local.virtualisation;
in
with lib; {
  options.local.virtualisation.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.virt-manager ];

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu.ovmf.enable = true;
    };
  };
}
