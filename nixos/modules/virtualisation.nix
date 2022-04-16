# TODO: find out where virt-manager configs are stored

{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.virt-manager ];

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.ovmf.enable = true;
  };
}
