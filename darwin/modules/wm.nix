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
          cmd - return : osascript -e 'if application "iTerm2" is running then' -e 'tell application "iTerm2" to create window with default profile' -e 'else' -e 'tell application "iTerm2" to activate' -e 'end if'

          cmd + shift - b : yabai -m space --balance
          cmd + shift - y : launchctl kickstart -k gui/501/org.nixos.yabai

          cmd - 0x2C : osascript -e 'tell application "iTerm2" to create window with default profile command "fish -C lf"'
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
        package = pkgs.yabai;
      };
    };
  };
}
