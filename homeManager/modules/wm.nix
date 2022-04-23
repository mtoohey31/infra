{ config, lib, pkgs, ... }:

with builtins; {
  assertions = [
    (lib.hm.assertions.assertPlatform "modules.wm" pkgs lib.platforms.linux)
  ];

  home.packages = with pkgs; [
    fuzzel
    flashfocus
    autotiling
    wob
    wl-clipboard
    sway-contrib.grimshot
    light
    pulsemixer
    headsetcontrol

    plover.wayland
    firefox
  ];

  programs = {
    fish = rec {
      shellAbbrs = {
        copy = "wl-copy";
        paste = "wl-paste";
      };
      shellAliases = shellAbbrs;
      loginShellInit = ''
        if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$SSH_CONNECTION" -a ! -f /.dockerenv
          exec sway
        end
      '';
    };
    mako = {
      enable = true;
      font = "JetBrainsMono Nerd Font Regular 16px";
      layer = "overlay";
      anchor = "bottom-right";
      borderSize = 0;
      margin = "16";
      extraConfig = ''
        [urgency=critical]
        background-color=#EE0000CC
      '';
    };
    qutebrowser.extraConfig = ''
      config.bind('wp', 'hint all spawn sh -c "wget \\\"{hint-url}\\\" -O ${config.xdg.cacheHome}/wallpaper && wal -c && wal -i ${config.xdg.cacheHome}/wallpaper"')
    '';
  };

  services.kanshi = {
    enable = true;
    profiles =
      let
        criteria = "Unknown TL140BDXP01-0 0x00000000";
        mode = "2560x1440@120Hz";
      in
      {
        docked-acer = {
          outputs = [
            {
              criteria = "Acer Technologies XV340CK P THQAA0013P00";
              mode = "3440x1440";
              position = "0,0";
              scale = 1.25;
            }
            {
              inherit criteria mode;
              scale = 1.75;
              position = "2752,960";
            }
          ];
        };
        docked-lg = {
          outputs = [
            {
              criteria = "Goldstar Company Ltd LG ULTRAWIDE 0x00000B3E";
              mode = "2560x1080@60Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              inherit criteria mode;
              position = "549,1080";
              scale = 1.75;
            }
          ];
        };
        docked-samsung = {
          outputs = [
            {
              criteria = "Samsung Electric Company S24B350 0x00007F58";
              mode = "1920x1080@60Hz";
              position = "0,0";
              scale = 1.15;
            }
            {
              inherit criteria mode;
              position = "1671,600";
              scale = 1.75;
            }
          ];
        };
        undocked = {
          outputs = [{
            inherit criteria;
            mode = "2560x1440@60.001Hz";
            position = "0,0";
            scale = 1.5;
          }];
        };
      };
  };

  xdg.configFile = {
    "sway/status" = {
      text = ''
        #!${pkgs.fish}/bin/fish
        ${readFile ./wm/status.fish}
      '';
      executable = true;
      inherit (config.xdg.configFile."sway/config") onChange;
    };
    "wal/templates/colors-sway-stripped".text = ''
      set $wallpapers {wallpaper.strip}

      set $backgrounds {background.strip}
      set $foregrounds {foreground.strip}

      set $color0s {color0.strip}
      set $color1s {color1.strip}
      set $color2s {color2.strip}
      set $color3s {color3.strip}
      set $color4s {color4.strip}
      set $color5s {color5.strip}
      set $color6s {color6.strip}
      set $color7s {color7.strip}
      set $color8s {color8.strip}
      set $color9s {color9.strip}
      set $color10s {color10.strip}
      set $color11s {color11.strip}
      set $color12s {color12.strip}
      set $color13s {color13.strip}
      set $color14s {color14.strip}
      set $color15s {color15.strip}
    '';
  };
  wayland.windowManager.sway =
    let
      wobsock = "$XDG_RUNTIME_DIR/wob.sock";
      mpvsock = "$XDG_RUNTIME_DIR/mpv.sock";
    in
    {
      enable = true;
      extraOptions = [ "--unsupported-gpu" ];
      extraConfigEarly = ''
        include ${config.xdg.cacheHome}/wal/colors-sway
        include ${config.xdg.cacheHome}/wal/colors-sway-stripped
        exec_always rm -f ${wobsock}; mkfifo ${wobsock} && tail -f ${wobsock} | wob -o 0 -b 0 -p 6 -H 28 --background-color "$foreground"CC --bar-color "$background"CC --overflow-background-color "$color1"CC --overflow-bar-color "$background"CC
        exec_always pkill mako; mako --background-color "$background"CC --text-color "$foreground"
      '';
      extraSessionCommands = ''
        export _JAVA_AWT_WM_NONREPARENTING=1
        export WLR_RENDERER_ALLOW_SOFTWARE=1
      '';
      # TODO: extraPackages = with pkgs; [ swaylock-effects swaybg swayidle ];
      extraConfig = ''
        default_border none
        mouse_warping container
        exec_always pkill flashfocus; flashfocus --flash-opacity 0.9 --time 200 --ntimepoints 30
        exec_always pkill autotiling; autotiling
        exec_always systemctl restart --user kanshi

        bindsym --locked XF86MonBrightnessUp exec light -A 2 && light -G | cut -d'.' -f1 > ${wobsock}
        bindsym --locked XF86MonBrightnessDown exec light -U 2 && light -G | cut -d'.' -f1 > ${wobsock}

        bindsym --locked Mod4+Up exec /bin/sh -c "pulsemixer --change-volume +2; pulsemixer --get-volume | awk '{ print \$1 }' > ${wobsock}"
        bindsym --locked XF86AudioRaiseVolume exec /bin/sh -c "pulsemixer --change-volume +2; pulsemixer --get-volume | awk '{ print \$1 }' > ${wobsock}"
        bindsym --locked Mod4+Down exec /bin/sh -c "pulsemixer --change-volume -2; pulsemixer --get-volume | awk '{ print \$1 }' > ${wobsock}"
        bindsym --locked XF86AudioLowerVolume exec /bin/sh -c "pulsemixer --change-volume -2; pulsemixer --get-volume | awk '{ print \$1 }' > ${wobsock}"

        bindsym --locked XF86KbdBrightnessUp exec fish -c "switch (asusctl -k | sed 's/^Current keyboard led brightness: //'); case 48; asusctl -k low; case 49; asusctl -k med; case 50; asusctl -k high; end"
        bindsym --locked XF86KbdBrightnessDown exec fish -c "switch (asusctl -k | sed 's/^Current keyboard led brightness: //'); case 49; asusctl -k off; case 50; asusctl -k low; case 51; asusctl -k med; end"

        for_window [title="floatme"] floating enable
        for_window [title="Bitwarden"] floating enable
      '';
      config = rec {
        fonts = {
          names = [ "JetBrainsMono Nerd Font" ];
          style = "Regular";
          size = 12.0;
        };
        modifier = "Mod4";
        terminal = "kitty";
        gaps = {
          inner = 16;
          outer = -16;
        };
        focus = { followMouse = true; };
        seat = { "*" = { hide_cursor = "1000"; }; };
        output."*".bg = "${config.xdg.cacheHome}/wallpaper fill";
        keybindings = {
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";

          "${modifier}+Shift+h" =
            "exec swaymsg -- mark --replace focused && swaymsg focus left && swaymsg swap container with mark focused && swaymsg [con_mark='^focused$'] focus && swaymsg unmark focused";
          "${modifier}+Shift+j" =
            "exec swaymsg -- mark --replace focused && swaymsg focus down && swaymsg swap container with mark focused && swaymsg [con_mark='^focused$'] focus && swaymsg unmark focused";
          "${modifier}+Shift+k" =
            "exec swaymsg -- mark --replace focused && swaymsg focus up && swaymsg swap container with mark focused && swaymsg [con_mark='^focused$'] focus && swaymsg unmark focused";
          "${modifier}+Shift+l" =
            "exec swaymsg -- mark --replace focused && swaymsg focus right && swaymsg swap container with mark focused && swaymsg [con_mark='^focused$'] focus && swaymsg unmark focused";
        } // (foldl'
          (s: i:
            s // {
              "${modifier}+${toString i}" = "workspace number ${toString i}";
            })
          { }
          (lib.range 0 9)) // (foldl'
          (s: i:
            s // {
              "${modifier}+Shift+${toString i}" =
                "move container to workspace number ${
                toString i
              }, workspace number ${toString i}";
            })
          { }
          (lib.range 0 9)) //

        {

          "${modifier}+Shift+tab" = "floating toggle";
          "${modifier}+tab" = "focus mode_toggle";

          "${modifier}+r" = ''mode "resize"'';
          "${modifier}+v" = ''mode "move"'';
          "${modifier}+escape" = ''mode "passthrough"'';

          "${modifier}+Shift+q" = "quit";
          "${modifier}+Shift+r" = "reload";
          "${modifier}+q" = "kill";
          "${modifier}+w" = "kill";

          "${modifier}+Shift+d" = "exec systemctl restart --user kanshi";

          "${modifier}+space" = ''exec fuzzel -x 14 -y 14 -p 14 --border-radius=0 --background-color=$backgrounds"BF" --text-color=$foregrounds"FF" --match-color=$color3s"FF" --selection-color=$color1s"FF" --selection-text-color=$foregrounds"FF" --border-color=00000000 --show drun'';
          "${modifier}+return" = "exec ${terminal}";
          "${modifier}+slash" = "exec ${terminal} -e fish -C lfcd";

          "${modifier}+Shift+space" = ''
            exec test -S ${mpvsock} && echo '{ "command": ["cycle", "pause"] }' | socat - ${mpvsock} || fish -C "tmux-music"'';
          "${modifier}+Shift+return" = "exec tmux kill-session -t music";
          "${modifier}+Shift+right" = ''
            exec echo '{ "command": ["playlist-next"] }' | socat - ${mpvsock}'';
          "${modifier}+Shift+left" = ''
            exec echo '{ "command": ["playlist-prev"] }' | socat - ${mpvsock}'';
          "${modifier}+Shift+down" = ''
            exec echo '{ "command": ["add", "volume", "-2"] }' | socat - ${mpvsock}'';
          "${modifier}+Shift+up" = ''
            exec echo '{ "command": ["add", "volume", "2"] }' | socat - ${mpvsock}'';

          "${modifier}+Shift+S" = "exec grimshot copy area";

          "${modifier}+p" = "exec qbpm launch personal";
          "${modifier}+g" = "exec qbpm launch gaming";
          "${modifier}+u" = "exec qbpm launch university";
          "${modifier}+m" = "exec qbpm launch mod";

          "${modifier}+Shift+p" = "exec brave --profile-directory=\"Default\"";
          "${modifier}+Shift+g" = "exec brave --profile-directory=\"Profile 2\"";
          "${modifier}+Shift+u" = "exec brave --profile-directory=\"Profile 3\"";
          "${modifier}+Shift+m" = "exec brave --profile-directory=\"Profile 4\"";
        };
        modes = {
          resize = {
            "h" = "resize shrink width 50px";
            "j" = "resize grow height 50px";
            "k" = "resize shrink height 50px";
            "l" = "resize grow width 50px";

            "Mod1+h" = "resize shrink width 5px";
            "Mod1+j" = "resize grow height 5px";
            "Mod1+k" = "resize shrink height 5px";
            "Mod1+l" = "resize grow width 5px";

            "Escape" = ''mode "default"'';
          };
          move = {
            "h" = "move left 50px";
            "j" = "move down 50px";
            "k" = "move up 50px";
            "l" = "move right 50px";

            "Mod1+h" = "move left 5px";
            "Mod1+j" = "move down 5px";
            "Mod1+k" = "move up 5px";
            "Mod1+l" = "move right 5px";

            "Escape" = ''mode "default"'';
          };
          passthrough = { "${modifier}+Escape" = ''mode "default"''; };
        };
        bars = [{
          inherit fonts;
          mode = "hide";
          position = "top";
          statusCommand = "${config.xdg.configHome}/sway/status";
          colors = {
            background = "$background";
            statusline = "$foreground";
            separator = "#000000";
            focusedWorkspace = {
              border = "$foreground";
              background = "$foreground";
              text = "$background";
            };
            activeWorkspace = {
              border = "$background";
              background = "$background";
              text = "$foreground";
            };
            inactiveWorkspace = {
              border = "$background";
              background = "$background";
              text = "$foreground";
            };
            urgentWorkspace = {
              border = "$color1";
              background = "$color1";
              text = "$background";
            };
            bindingMode = {
              border = "$background";
              background = "$background";
              text = "$foreground";
            };
          };
          extraConfig = "height 22";
        }];
        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "disabled";
          };
          "type:pointer".accel_profile = "flat";
        };
      };
    };
}
