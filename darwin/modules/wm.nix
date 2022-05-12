_:
{ config, lib, pkgs, ... }:

let cfg = config.local.wm;
in
with lib; {
  options.local.wm.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    launchd.user.agents.skhd.serviceConfig.EnvironmentVariables.SHELL = "${pkgs.bash}/bin/bash";
    services = {
      skhd = {
        enable = true;
        skhdConfig = ''
          cmd - h : yabai -m window --focus west
          cmd - j : yabai -m window --focus south
          cmd - k : yabai -m window --focus north
          cmd - l : yabai -m window --focus east

          cmd + shift - h : yabai -m window --swap west
          cmd + shift - j : yabai -m window --swap south
          cmd + shift - k : yabai -m window --swap north
          cmd + shift - l : yabai -m window --swap east

          cmd + shift - tab : yabai -m window --toggle float
          cmd - return : kitty -d ~

          cmd + shift - b : yabai -m space --balance
          cmd + shift - y : launchctl kickstart -k gui/501/org.nixos.yabai

          cmd - 0x2C : kitty -d ~ -e fish -C 'lf'
          cmd + shift - 0x2C : open ~
        '';
      };
      yabai = {
        enable = true;
        enableScriptingAddition = true;
        config = {
          mouse_follows_focus = "on";
          focus_follows_mouse = "autoraise";
          window_topmost = "on";
          window_shadow = "float";
          mouse_modifier = "cmd";
          mouse_action1 = "move";
          mouse_action2 = "resize";
          mouse_drop_action = "swap";
          layout = "bsp";
          window_gap = 16;
        };
        package = pkgs.yabai.overrideAttrs (_: {
          version = "4.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "koekeishiya";
            repo = "yabai";
            rev = "910fb43b57866dc6eaa000331bb1b77d91bf245b";
            sha256 = "9YYYUzNCXEOLOlBmVtPOMW0ikFCvGCl9YnK6NPue3kA=";
          };
          # TODO: please don't look too close at this :see_no_evil:
          prePatch = ''
            substituteInPlace makefile \
                --replace xcrun 'SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX12.3.sdk /usr/bin/xcrun'
          '';
        });
      };
    };
  };
}
