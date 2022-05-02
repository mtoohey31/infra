{ ... }:

{
  local.primary-user.homeManagerUser = "server";

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
