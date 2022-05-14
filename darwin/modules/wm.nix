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
    services = let mod = "cmd"; in
      {
        skhd = {
          enable = true;
          skhdConfig = ''
            ${mod} - h : yabai -m window --focus west || yabai -m display --focus west
            ${mod} - j : yabai -m window --focus south || yabai -m display --focus south
            ${mod} - k : yabai -m window --focus north || yabai -m display --focus north
            ${mod} - l : yabai -m window --focus east || yabai -m display --focus east

            ${mod} + shift - h : (yabai -m window --swap west && sleep 0.1 && yabai -m window --focus mouse && sleep 0.1 && yabai -m window --focus recent) || (yabai -m display --focus west && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
            ${mod} + shift - j : (yabai -m window --swap south && sleep 0.1 && yabai -m window --focus mouse && sleep 0.1 && yabai -m window --focus recent) || (yabai -m display --focus south && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
            ${mod} + shift - k : (yabai -m window --swap north && sleep 0.1 && yabai -m window --focus mouse && sleep 0.1 && yabai -m window --focus recent) || (yabai -m display --focus north && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)
            ${mod} + shift - l : (yabai -m window --swap east && sleep 0.1 && yabai -m window --focus mouse && sleep 0.1 && yabai -m window --focus recent) || (yabai -m display --focus east && sleep 0.1 && yabai -m window --swap recent && yabai -m window --focus recent)

            ${mod} + shift - tab : yabai -m window --toggle float
            ${mod} - return : osascript -e 'if application "iTerm2" is running then' -e 'tell application "iTerm2" to create window with default profile' -e 'else' -e 'tell application "iTerm2" to activate' -e 'end if'

            ${mod} + shift - b : yabai -m space --balance
            ${mod} + shift - y : launchctl kickstart -k gui/501/org.nixos.yabai

            ${mod} - 0x2C : osascript -e 'tell application "iTerm2" to create window with default profile command "fish -C lf"'
            ${mod} + shift - 0x2C : open ~
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
            mouse_modifier = mod;
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
