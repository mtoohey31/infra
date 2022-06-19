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

  hardware.fancontrol = {
    enable = true;
    config = ''
      INTERVAL=2
      DEVPATH=hwmon0=devices/pci0000:00/0000:00:14.0/usb1/1-12/1-12:1.0/0003:1B1C:0C10.0001
      DEVNAME=hwmon2=coretemp hwmon0=corsaircpro
      FCTEMPS=hwmon0/pwm1=hwmon2/temp1_input hwmon0/pwm2=hwmon2/temp1_input hwmon0/pwm3=hwmon2/temp1_input hwmon0/pwm4=hwmon2/temp1_input hwmon0/pwm5=hwmon2/temp1_input hwmon0/pwm6=hwmon2/temp1_input
      FCFANS=hwmon0/pwm1=hwmon0/fan1_input hwmon0/pwm2=hwmon0/fan2_input hwmon0/pwm3=hwmon0/fan3_input hwmon0/pwm4=hwmon0/fan4_input hwmon0/pwm5=hwmon0/fan5_input hwmon0/pwm6=hwmon0/fan6_input
      MINTEMP=hwmon0/pwm1=50 hwmon0/pwm2=50 hwmon0/pwm3=50 hwmon0/pwm4=50 hwmon0/pwm5=50 hwmon0/pwm6=50
      MAXTEMP=hwmon0/pwm1=75 hwmon0/pwm2=75 hwmon0/pwm3=75 hwmon0/pwm4=75 hwmon0/pwm5=75 hwmon0/pwm6=75
      MINSTART=hwmon0/pwm1=32 hwmon0/pwm2=32 hwmon0/pwm3=32 hwmon0/pwm4=32 hwmon0/pwm5=32 hwmon0/pwm6=32
      MINSTOP=hwmon0/pwm1=2 hwmon0/pwm2=2 hwmon0/pwm3=2 hwmon0/pwm4=2 hwmon0/pwm5=2 hwmon0/pwm6=2
      MINPWM=hwmon0/pwm1=0 hwmon0/pwm2=0 hwmon0/pwm3=0 hwmon0/pwm4=0 hwmon0/pwm5=0 hwmon0/pwm6=0
    '';
  };

  networking.hostId = "977b87b2";

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
