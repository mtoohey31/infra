{ lib, pkgs, ... }:

{
  users = lib.mkPrimaryUser { username = "mtoohey"; } pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg { user = "server"; };

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [
        # TODO
      ];
      peers = [
        # TODO
      ];
    };
  };
}
