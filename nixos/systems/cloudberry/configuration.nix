inputs:
{ config, lib, pkgs, ... }:

(import (inputs.nixpkgs + "/nixos/modules/profiles/all-hardware.nix")
  { inherit lib pkgs; }) // {
  imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];
  disabledModules = [ "profiles/all-hardware.nix" ];

  local.sops.enable = true;

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

  sops.secrets.cloudflare_config.sopsFile = ./secrets.yaml;
  services.caddy = {
    enable = true;
    package = pkgs.caddy-cloudflare;
    extraConfig = config.sops.secrets.cloudflare_config.path;
  };

  services.home-assistant = {
    enable = true;
    config = {
      default_config = { };
      tplink = {
        discovery = false;
        switch = [
          { host = "192.168.86.21"; }
          { host = "192.168.86.165"; }
          { host = "192.168.86.166"; }
          { host = "192.168.86.201"; }
        ];
      };
      binary_sensor = [{
        platform = "flic";
        host = "192.168.86.24";
      }];
      camera = {
        platform = "generic";
        name = "!secret traffic_cam_name";
        still_image_url = "!secret traffic_cam_url";
      };
      sensor = [
        { platform = "google_wifi"; }
        {
          platform = "waze_travel_time";
          name = "Work Travel Time";
          origin = "!secret waze_origin";
          destination = "!secret waze_destination";
          region = "US";
          avoid_ferries = true;
          avoid_toll_roads = true;
          avoid_subscription_roads = true;
        }
      ];
      wake_on_lan = { };
      switch = [{
        platform = "wake_on_lan";
        name = "NAS";
        mac = "!secret server_mac_address";
        host = "!secret server_ip_address";
        turn_off = { service = "shell_command.turn_off_nas"; };
      }];
      shell_command = { turn_off_nas = "!secret server_off_command"; };
      homekit = [{
        name = "Home Assistant Bridge";
        port = 51827;
        filter = {
          include_entities = [
            "switch.chandelier"
            "switch.lamp"
            "switch.outside_lights"
            "switch.nas"
          ];
        };
        entity_config = {
          "switch.chandelier" = { name = "Chandelier"; };
          "switch.lamp" = { name = "Lamp"; };
          "switch.outside_lights" = { name = "Lights"; };
          "switch.nas" = { name = "NAS"; };
        };
      }];
      homeassistant = {
        customize = {
          # TODO
        };
      };
      group = {
        # TODO
      };
      automation = {
        # TODO
      };
      script = {
        # TODO
      };
      scene = {
        # TODO
      };
    };
  };
}
