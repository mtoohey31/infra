inputs:
{ config, lib, pkgs, ... }:

# TODO: fix needing to reload on startup

let cfg = config.local.wm; in
with lib; {
  options.local.wm.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "modules.wm" pkgs lib.platforms.linux)
    ];

    xdg.desktopEntries = {
      emoji-picker = {
        type = "Application";
        name = "Emoji Picker";
        exec = "emoji";
        terminal = false;
      };
      poweroff = {
        type = "Application";
        name = "Poweroff";
        exec = "poweroff";
        terminal = false;
      };
      reboot = {
        type = "Application";
        name = "Reboot";
        exec = "reboot";
        terminal = false;
      };
      sleep = {
        type = "Application";
        name = "Sleep";
        exec = "systemctl suspend";
        terminal = false;
      };
      suspend = {
        type = "Application";
        name = "Suspend";
        exec = "systemctl suspend";
        terminal = false;
      };
    };

    home = {
      packages = with pkgs; [
        (pkgs.symlinkJoin {
          name = "fuzzel-wrapped";
          paths = [
            (pkgs.writeShellScriptBin "fuzzel" ''
              . ${config.xdg.cacheHome}/wal/colors-stripped.sh
              exec ${pkgs.fuzzel}/bin/fuzzel -x 14 -y 14 -p 14 -w 42 --border-radius=0 --background-color="''${backgrounds}BF" --text-color="''${foreground}FF" --match-color="''${color3}FF" --selection-color="''${color1}FF" --selection-text-color="''${foreground}FF" --border-color=00000000 "$@" --font="JetBrainsMono Nerd Font"
            '')
            fuzzel
          ];
        })
        (pkgs.writeShellScriptBin "emoji" ''
          jq -r '.[] | ([.description] + .aliases)[] + ": " + .emoji' ${inputs.gemoji}/db/emoji.json | fuzzel -dmenu | grep -o '.$' | tr -d '\n' | wl-copy
        '')
        flashfocus
        autotiling
        wob
        wl-clipboard
        sway-contrib.grimshot
        swaylock-effects
        swayidle
        light
        pulsemixer
        headsetcontrol
        uncommitted-go

        plover.wayland
        firefox
      ];
      pointerCursor = {
        name = "Vanilla-DMZ";
        package = pkgs.vanilla-dmz;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    };

    programs = {
      fish = rec {
        shellAbbrs = {
          copy = "wl-copy";
          paste = "wl-paste";
        };
        shellAliases = shellAbbrs;
        loginShellInit = ''
          if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$SSH_CONNECTION"
            exec sway
          end
        '';
      };
      i3status-rust = {
        enable = true;
        bars = {
          default = {
            icons = "material-nf";
            theme = "native";
            blocks = [
              {
                block = "custom";
                command = "if ip link show wg0 &>/dev/null; echo 嬨; end";
                hide_when_empty = true;
              }
              {
                block = "net";
                format = "{ssid}";
              }
              {
                block = "custom";
                command = ''
                  if set graphics "$(supergfxctl -g | string replace -r '^Current graphics mode: ' "")"
                      echo " $graphics"
                  else
                      echo  misbehaving
                  end
                '';
                interval = 5;
              }
              {
                block = "custom";
                command = ''
                  set -e vms
                  set -a vms (virsh list | tail -n +3 | head -n -1 | awk '{ print $2 }')
                  if count $vms > /dev/null
                    echo "  $(string join ', ' $vms)"
                  end
                '';
                hide_when_empty = true;
                interval = 60;
              }
              {
                block = "custom";
                command = ''
                  set free_size "$(df -h / | tail -n1 | cut -d' ' -f4)"
                  if test "$(echo "$free_size" | tr -d '[:alpha:]')" -le 100
                      echo " $free_size"
                  end
                '';
                hide_when_empty = true;
                interval = 300;
              }
              {
                block = "custom";
                command = ''
                  if set hs_bat "$(headsetcontrol -cb 2> /dev/null)"
                      echo " $hs_bat%"
                  end
                '';
                hide_when_empty = true;
              }
              { block = "sound"; }
              {
                block = "custom";
                command = ''
                  if test -S "$XDG_RUNTIME_DIR/mpv.sock" && set state "$(echo '{ "command": ["get_property", "pause"] }' | socat - $XDG_RUNTIME_DIR/mpv.sock 2> /dev/null)"
                      if test "$(echo "$state" | jq -r '.data')" = true
                          echo 契
                      else
                          echo 
                      end

                      echo "$(echo '{ "command": ["get_property", "media-title"] }' | socat - "$XDG_RUNTIME_DIR/mpv.sock" | jq -r '.data')"

                      set artist "$(echo '{ "command": ["get_property", "metadata/artist"] }' | socat - "$XDG_RUNTIME_DIR/mpv.sock" | jq -r '.data')"

                      if test "$artist" != null
                          echo "- $artist"
                      end
                  end
                '';
                hide_when_empty = true;
                interval = 0.5;
              }
              {
                block = "custom";
                command = ''
                  if test -d ~/repos && set num_uncommitted (uncommitted -n ~/repos)
                      echo '{ "state": "Warning", "text": "'" $num_uncommitted"'" }'
                  end
                '';
                hide_when_empty = true;
                json = true;
                interval = 300;
              }
              { block = "battery"; }
              # TODO: upstream an option for hiding the builtin disk_space
              # block below a certain threshold
              {
                block = "custom";
                command = ''
                  set free_size "$(df -h / | tail -n1 | awk '{ print $4 }')"
                  if test "$(echo "$free_size" | tr -d '[:alpha:]')" -le 100
                      echo " $free_size"
                  end
                '';
                hide_when_empty = true;
                interval = 300;
              }
              {
                block = "time";
                format = "  %a. %b %-d  %-I:%M:%S %p";
                icons_format = "";
                interval = 1;
              }
            ];
          };
        };
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
                position = "1450,1152";
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
      "wal/templates/colors-stripped.sh".text = ''
        # Shell variables
        # Generated by 'wal'
        wallpaper="{wallpaper.strip}"

        # Special
        background='{background.strip}'
        foreground='{foreground.strip}'
        cursor='{cursor.strip}'

        # Colors
        color0='{color0.strip}'
        color1='{color1.strip}'
        color2='{color2.strip}'
        color3='{color3.strip}'
        color4='{color4.strip}'
        color5='{color5.strip}'
        color6='{color6.strip}'
        color7='{color7.strip}'
        color8='{color8.strip}'
        color9='{color9.strip}'
        color10='{color10.strip}'
        color11='{color11.strip}'
        color12='{color12.strip}'
        color13='{color13.strip}'
        color14='{color14.strip}'
        color15='{color15.strip}'
      '';
    };
    wayland.windowManager.sway =
      let wobsock = "$XDG_RUNTIME_DIR/wob.sock"; in
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
        extraConfig = ''
          default_border none
          mouse_warping container
          exec_always pkill swayidle; swayidle before-sleep "swaylock -f --screenshots --font \\"JetBrainsMono Nerd Font\\" --effect-blur 32x5 --effect-vignette 0.5:0.5 --ring-color \\"$foreground\\" --line-color 00000000 --inside-color \\"$backgroundCC\\" --separator-color 00000000"
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
          terminal = pkgs.kitty-window;
          gaps = {
            inner = 16;
            outer = -16;
          };
          focus = { followMouse = true; };
          seat = {
            "*" = {
              hide_cursor = "1000";
              xcursor_theme = "Vanilla-DMZ 24";
            };
          };
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

            "${modifier}+space" = ''exec fuzzel --show drun'';
            "${modifier}+return" = "exec ${terminal}";
            "${modifier}+slash" = "exec ${terminal} -e fish -C lfcd";

            "${modifier}+Shift+S" = "exec grimshot copy area";

            "${modifier}+p" = ''exec echo '{"args":[""], "target_arg":"", "protocol_version":1}' | ${pkgs.bash}/bin/bash -c "if test -e ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/personal/runtime/*; then socat - ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/personal/runtime/*; else qbpm launch personal; fi"'';
            "${modifier}+g" = ''exec echo '{"args":[""], "target_arg":"", "protocol_version":1}' | ${pkgs.bash}/bin/bash -c "if test -e ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/gaming/runtime/*; then socat - ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/gaming/runtime/*; else qbpm launch gaming; fi"'';
            "${modifier}+u" = ''exec echo '{"args":[""], "target_arg":"", "protocol_version":1}' | ${pkgs.bash}/bin/bash -c "if test -e ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/university/runtime/*; then socat - ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/university/runtime/*; else qbpm launch university; fi"'';
            "${modifier}+m" = ''exec echo '{"args":[""], "target_arg":"", "protocol_version":1}' | ${pkgs.bash}/bin/bash -c "if test -e ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/mod/runtime/*; then socat - ${config.home.homeDirectory}/.local/share/qutebrowser-profiles/mod/runtime/*; else qbpm launch mod; fi"'';

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
            statusCommand = "i3status-rs '${config.xdg.configHome}/i3status-rust/config-default.toml'";
            colors = {
              background = "$background";
              statusline = "$foreground";
              separator = "$foreground";
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
  };
}
