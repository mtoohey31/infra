{ config, lib, flake-inputs, ... }:

let
  cfg = config.local.sops;
  inherit (config.local.primary-user) username;
in
with lib; {
  imports = [ flake-inputs.sops-nix.nixosModules.sops ];

  options.local.sops.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    assertions = [
      { assertion = config.local.primary-user.enable; }
    ];

    sops.defaultSopsFile = ../../secrets/activation.yaml;
    sops.age.sshKeyPaths = [
      (config.users.users."${username}".home + "/.ssh/id_ed25519")
    ];
  };
}