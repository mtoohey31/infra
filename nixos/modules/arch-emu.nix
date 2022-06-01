# source: https://github.com/cleverca22/nixos-configs/blob/master/qemu.nix
_:
{ config, lib, pkgs, ... }:

let cfg = config.local.arch-emu;
in
with lib; {
  options.local.arch-emu.aarch64.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.aarch64.enable {
    boot.binfmt.registrations.aarch64 = {
      interpreter = "${pkgs.qemu}/bin/qemu-aarch64";
      magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00'';
      mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\x00\xff\xfe\xff\xff\xff'';
    };
    nix = {
      extraOptions = ''
        extra-platforms = aarch64-linux i686-linux
      '';
      sandboxPaths = [ "/run/binfmt" "${pkgs.qemu}" ];
    };
  };
}
