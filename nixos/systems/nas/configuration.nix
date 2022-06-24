{ config, pkgs, ... }:

let inherit (config.local.primary-user) username; in
{
  imports = [ ./hardware-configuration.nix ];

  local = {
    fan2go = {
      enable = true;
      config = {
        api = {
          enabled = false;
          host = "localhost";
          port = 9001;
        };
        controllerAdjustmentTickRate = "200ms";
        curves = [
          {
            id = "cpu_curve";
            linear = {
              sensor = "cpu_package";
              steps = [
                {
                  "45" = 0;
                }
                {
                  "55" = 50;
                }
                {
                  "80" = 255;
                }
              ];
            };
          }
          {
            id = "gpu_curve";
            linear = {
              sensor = "gpu";
              steps = [
                {
                  "45" = 0;
                }
                {
                  "55" = 50;
                }
                {
                  "80" = 255;
                }
              ];
            };
          }
        ];
        dbPath = "/var/db/fan2go/fan2go.db";
        fans = [
          {
            curve = "gpu_curve";
            hwmon = {
              index = 1;
              platform = "corsaircpro";
            };
            id = "front_bottom";
            neverStop = false;
            startPwm = 30;
          }
          {
            curve = "cpu_curve";
            hwmon = {
              index = 2;
              platform = "corsaircpro";
            };
            id = "front_middle";
            neverStop = false;
          }
          {
            curve = "cpu_curve";
            hwmon = {
              index = 3;
              platform = "corsaircpro";
            };
            id = "front_top";
            neverStop = false;
          }
          {
            curve = "cpu_curve";
            hwmon = {
              index = 4;
              platform = "corsaircpro";
            };
            id = "top_front";
            neverStop = false;
          }
          {
            curve = "cpu_curve";
            hwmon = {
              index = 5;
              platform = "corsaircpro";
            };
            id = "top_back";
            neverStop = false;
          }
          {
            curve = "gpu_curve";
            hwmon = {
              index = 6;
              platform = "corsaircpro";
            };
            id = "back";
            neverStop = false;
          }
        ];
        maxRpmDiffForSettledFan = 10;
        rpmPollingRate = "1s";
        rpmRollingWindowSize = 10;
        runFanInitializationInParallel = false;
        sensors = [
          {
            hwmon = {
              index = 1;
              platform = "coretemp";
            };
            id = "cpu_package";
          }
          {
            hwmon = {
              index = 1;
              platform = "nouveau";
            };
            id = "gpu";
          }
        ];
        statistics = {
          enabled = false;
          port = 9000;
        };
        tempRollingWindowSize = 10;
        tempSensorPollingRate = "200ms";
      };
    };
    primary-user.homeManagerCfg = { config, ... }: {
      home.file.music.source = config.lib.file.mkOutOfStoreSymlink
        "/tank/media/music.git";
    };
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

  networking = {
    hostId = "977b87b2";
    interfaces.enp0s31f6.wakeOnLan.enable = true;
  };

  sops.secrets = {
    github_token = {
      owner = username;
      group = username;
    };
    hourly_cron_script = {
      owner = username;
      group = username;
    };
    post_gickup_script = {
      owner = username;
      group = username;
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
