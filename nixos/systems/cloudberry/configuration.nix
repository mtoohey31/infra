inputs:
{ config, lib, pkgs, ... }:

(import (inputs.nixpkgs + "/nixos/modules/profiles/all-hardware.nix")
  { inherit lib pkgs; }) // {
  imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];
  disabledModules = [ "profiles/all-hardware.nix" ];

  local = {
    primary-user.homeManagerCfg = { ... }: { };
    ssh.authorizedHosts = [ "air" "pixel" "zephyrus" ];
    sops.enable = true;
  };

  boot = {
    loader.systemd-boot.enable = false;
    initrd.availableKernelModules = (builtins.filter
      (module: ! builtins.elem module [
        "sun4i-drm"
        "sun8i-mixer"
        "pwm-sun4i"
        "dw-mipi-dsi"
        "rockchipdrm"
        "rockchip-rga"
        "phy-rockchip-pcie"
        "pcie-rockchip-host"
      ])
      (import
        (inputs.nixpkgs + "/nixos/modules/profiles/all-hardware.nix")
        { inherit lib pkgs; }).boot.initrd.availableKernelModules);
  };

  sops.secrets.home_assistant_secrets = {
    owner = config.users.users.hass.name;
    inherit (config.users.users.hass) group;
    sopsFile = ./secrets.yaml;
  };
  systemd.services.home-assistant.preStart = ''
    rm -f ${config.services.home-assistant.configDir}/secrets.yaml
    ln -s ${config.sops.secrets.home_assistant_secrets.path} \
      ${config.services.home-assistant.configDir}/secrets.yaml
  '';
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "backup"
      "default_config"
      "esphome"
      "flic"
      "homekit"
      "homekit_controller"
      "met"
      "tplink"
      "wake_on_lan"
    ];
    openFirewall = true;
    config = {
      default_config = { };
      met = { };
      tplink = {
        discovery = false;
        switch = [
          {
            entity_id = "switch.lamp";
            name = "Lamp";
            host = "!secret lamp_ip";
          }
          {
            entity_id = "switch.lights";
            name = "Lights";
            host = "!secret lights_ip";
          }
          {
            entity_id = "switch.chandelier";
            name = "Chandelier";
            host = "!secret chandelier_ip";
          }
        ];
      };
      binary_sensor = [{
        platform = "flic";
        host = "!secret flic_ip";
      }];
      wake_on_lan = { };
      switch = [
        {
          platform = "wake_on_lan";
          name = "NAS";
          mac = "!secret server_mac";
          host = "!secret server_ip";
          turn_off.service = "shell_command.turn_off_nas";
        }
      ];
      shell_command.turn_off_nas = "!secret server_off_command";
      homekit = [{
        name = "Home Assistant Bridge";
        filter = {
          include_entities = [
            "switch.chandelier"
            "switch.lamp"
            "switch.outside_lights"
            "switch.nas"
          ];
        };
        entity_config = {
          "switch.chandelier".name = "Chandelier";
          "switch.lamp".name = "Lamp";
          "switch.outside_lights".name = "Lights";
          "switch.nas".name = "NAS";
        };
      }];
      homeassistant = {
        customize = {
          "switch.nas".icon = "mdi:nas";
          "switch.chandelier".icon = "mdi:ceiling-light";
          "switch.lamp".icon = "mdi:floor-lamp";
          "switch.outside_lights".icon = "mdi:lightbulb-group";
        };
      };
      automation = [
        {
          action = [{
            service = "switch.toggle";
            target.entity_id = "switch.chandelier";
          }];
          alias = "Toggle Chandelier";
          condition = [ ];
          description = "";
          id = "1603767740442";
          mode = "single";
          trigger = [
            {
              event_data = {
                button_name = "!secret wall_flic";
                click_type = "single";
              };
              event_type = "flic_click";
              platform = "event";
            }
            {
              event_data = {
                button_name = "!secret desk_flic";
                click_type = "single";
              };
              event_type = "flic_click";
              platform = "event";
            }
          ];
        }
        {
          action = [{
            service = "switch.toggle";
            target.entity_id = "switch.lamp";
          }];
          alias = "Toggle Lamp";
          condition = [ ];
          description = "";
          id = "1603768200755";
          mode = "single";
          trigger = [{
            event_data = {
              button_name = "!secret lamp_flic";
              click_type = "single";
            };
            event_type = "flic_click";
            platform = "event";
          }];
        }
        {
          action = [
            {
              service = "switch.turn_off";
              target.entity_id = "switch.chandlier";
            }
            {
              service = "switch.turn_off";
              target.entity_id = "switch.lamp";
            }
          ];
          alias = "Inside Lights Off";
          condition = [ ];
          description = "";
          id = "1603767770535";
          mode = "single";
          trigger = [{
            event_data = {
              button_name = "!secret wall_flic";
              click_type = "hold";
            };
            event_type = "flic_click";
            platform = "event";
          }];
        }
        {
          action = [{
            service = "switch.turn_on";
            target.entity_id = "switch.outside_lights";
          }];
          alias = "Outside Lights On";
          condition = [ ];
          description = "";
          id = "1616991316310";
          mode = "single";
          trigger = [{
            event = "sunset";
            platform = "sun";
          }];
        }
        {
          action = [{
            service = "switch.turn_off";
            target.entity_id = "switch.outside_lights";
          }];
          alias = "Outside Lights Off";
          condition = [ ];
          description = "";
          id = "1616991271753";
          mode = "single";
          trigger = [{
            at = "23:30:00";
            platform = "time";
          }];
        }
        {
          action = [{
            service = "switch.turn_on";
            target.entity_id = "switch.nas";
          }];
          alias = "Server On";
          condition = [ ];
          description = "";
          id = "1622914949754";
          mode = "single";
          trigger = [{
            at = "7:00";
            platform = "time";
          }];
        }
        {
          action = [{
            service = "switch.turn_off";
            target.entity_id = "switch.nas";
          }];
          alias = "Server Off";
          condition = [ ];
          description = "";
          id = "1622915011141";
          mode = "single";
          trigger = [{
            at = "00:00";
            platform = "time";
          }];
        }
      ];
    };
  };
}
