{ config, pkgs, stdenv, ... }:

let lib = import ../../lib;
in {
  users = lib.mkPrimaryUser { username = "mtoohey"; } pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg {
    user = "server";
    username = "mtoohey";
  };

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
