{ pkgs, ... }:

let lib = import ../../../lib { lib = pkgs.lib; };
in
{
  users = lib.mkPrimaryUser { username = "tooheys"; } pkgs;

  services.samba = {
    enable = true;
    shares = {
      backups = {
        path = "/tank/backups";
        "valid users" = "tooheys";
        public = "no";
        writable = "yes";
        printable = "no";
      };
      media = {
        path = "/tank/media";
        "valid users" = "tooheys";
        public = "no";
        writable = "yes";
        printable = "no";
      };
    };
  };

  services.zfs = {
    enable = true;
    autoScrub = {
      interval = "monthly";
      pools = [ "tank" ];
    };
    expandOnBoot = [ "tank" ];
  };

  networking.hostId = "977b87b2";
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = { enableUnstable = true; };
  };
}
