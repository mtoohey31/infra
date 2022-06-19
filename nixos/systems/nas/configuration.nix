{ config, pkgs, ... }:

let inherit (config.local.primary-user) username; in
{
  imports = [ ./hardware-configuration.nix ];

  local = {
    primary-user.homeManagerCfg = { ... }: { };
    sops.enable = true;
    ssh.authorizedHosts = [ "air" "pixel" "zephyrus" ];
    wireguard-client.routeAll = false;
  };

  boot = {
    loader.systemd-boot.enable = true;
    supportedFilesystems = [ "zfs" ];
    zfs = {
      enableUnstable = true;
      extraPools = [ "tank" ];
    };
  };

  networking.hostId = "977b87b2";

  sops.secrets = {
    github_token = {
      owner = username;
      group = username;
      sopsFile = ./secrets.yaml;
    };
    hourly_cron_script = {
      owner = username;
      group = username;
      sopsFile = ./secrets.yaml;
    };
    post_gickup_script = {
      owner = username;
      group = username;
      sopsFile = ./secrets.yaml;
    };
  };
  services = {
    cron = {
      enable = true;
      systemCronJobs =
        let
          gickupCfg = (pkgs.formats.yaml { }).generate "gickup.yaml" {
            destination.local = [{
              path = "/tank/backups/git";
              structured = true;
            }];
            source.github = [{
              exclude = [ "nixpkgs" ];
              token_file = config.sops.secrets.github_token.path;
              ssh = true;
              sshkey = config.users.users."${username}".home
                + "/.ssh/id_ed25519";
              starred = true;
              wiki = true;
            }];
          };
        in
        [
          "@hourly ${username} ${pkgs.gickup}/bin/gickup ${gickupCfg} && ${pkgs.bash}/bin/bash ${config.sops.secrets.post_gickup_script.path}"
          "@hourly ${username} ${pkgs.bash}/bin/bash ${config.sops.secrets.hourly_cron_script.path}"
        ];
    };

    # TODO: figure out how to set user password automatically, or sync it with
    # the linux user password
    samba = {
      enable = true;
      openFirewall = true;
      shares = {
        backups = {
          path = "/tank/backups";
          "valid users" = username;
          public = "no";
          writable = "yes";
          printable = "no";
        };
        media = {
          path = "/tank/media";
          "valid users" = username;
          public = "no";
          writable = "yes";
          printable = "no";
        };
      };
    };

    zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
        pools = [ "tank" ];
      };
    };
  };
}
