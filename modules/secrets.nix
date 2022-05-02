{ lib, ... }:

with lib; {
  options.local.secrets = mkOption {
    type = types.attrs;
    default = import ../secrets.nix;
  };
}
