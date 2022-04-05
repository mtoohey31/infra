{ config, pkgs, stdenv, ... }:

let lib = import ../../lib;
in {
  users = lib.mkPrimaryUser { username = "mtoohey"; } pkgs;
  home-manager.users.mtoohey = lib.mkHomeCfg "server" pkgs;

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
