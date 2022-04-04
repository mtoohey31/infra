{ config, lib, pkgs, ... }:

# TODO:
#
# kmonad
# scripts
# check dotfiles repo for any other configs that need to get picked up
# make cursor not tiny

with builtins;
let lib = import ../lib;
in {
  xdg.configFile."kitty/search".source = fetchTarball {
    url =
      "https://github.com/trygveaa/kitty-kitten-search/archive/8cc3237e6a995b6e7e101cba667fcda5439d96e2.tar.gz";
    sha256 = "0h4zryamysalv80dgdwrlfqanx45xl7llmlmag0limpa3mqs0hs3";
  };

  home.packages = with pkgs; [
    nsxiv
    pywal
    wofi # TODO: remove after fuzzel is working
    # fuzzel TODO: depends on https://gitlab.gnome.org/GNOME/librsvg/-/issues/856
    flashfocus
    autotiling
    wob
    wl-clipboard
    sway-contrib.grimshot
    light
    socat
    pulsemixer

    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override {
      fonts = [ "JetBrainsMono" ];
    }) # TODO: reconsider making this a variable
  ];

  programs = {
    # TODO: add qutebrowser, profiles, and keybindings
    brave = {
      enable = true;
      # TODO: figure out how to add profile sync and add keybindings
    };
    fish = {
      loginShellInit = ''
        if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$SSH_CONNECTION" -a ! -f /.dockerenv
          exec sway
        end
      '';
    };
    kitty = {
      enable = true;
      environment = { SHLVL = "0"; };
      settings = {
        cursor = "none";
        cursor_text_color = "background";
        cursor_blink_interval = 0;
        window_padding_width = 8;
        hide_window_decorations = true;
        background_opacity = "0.8";
        remember_window_size = false;
        enable_audio_bell = false;
        update_check_interval = 0;
        macos_quit_when_last_window_closed = true;
        touch_scroll_multiplier = 9;
      };
      keybindings = {
        "shift+enter" = "send_text all \\x1b[13;2u";
        "ctrl+enter" = "send_text all \\x1b[13;5u";
        "ctrl+l" =
          "combine : clear_terminal scrollback active : send_text normal,application \\x0c";
        "ctrl+shift+f" =
          "launch --location=hsplit --allow-remote-control kitty +kitten search/search.py @active-kitty-window-id";
      };
      extraConfig = ''
        font_family JetBrains Mono Regular Nerd Font Complete
        bold_font JetBrains Mono Bold Nerd Font Complete
        italic_font JetBrains Mono Italic Nerd Font Complete
        bold_italic_font JetBrains Mono Bold Italic Nerd Font Complete
        font_size 12

        include $HOME/.cache/wal/colors-kitty.conf
      '';
    };
    # TODO: get pywal colours working
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
    mpv = {
      enable = true;
      config = {
        osc = false;
        script-opts-add = "osc-visibility=always";
        osd-font = "JetBrainsMono Nerd Font";
        ytdl-format =
          ''ytdl-format="bestvideo[height<=1440]+bestaudio/best[height<=1440]'';
        input-default-bindings = false;
      };
      bindings = {
        SPACE = "cycle pause";

        LEFT = "seek -5";
        DOWN = "add volume -2";
        UP = "add volume 2";
        RIGHT = "seek 5";

        h = "seek -5";
        j = "add volume -2";
        k = "add volume 2";
        l = "seek 5";

        WHEEL_DOWN = "add volume -2";
        WHEEL_UP = "add volume 2";

        "(" = "add speed -0.25";
        ")" = "add speed +0.25";

        n = "playlist-next";
        N = "playlist-prev";

        g = "seek 0 absolute-percent";
        "0" = "seek 0 absolute-percent";
        "1" = "seek 10 absolute-percent";
        "2" = "seek 20 absolute-percent";
        "3" = "seek 30 absolute-percent";
        "4" = "seek 40 absolute-percent";
        "5" = "seek 50 absolute-percent";
        "6" = "seek 60 absolute-percent";
        "7" = "seek 70 absolute-percent";
        "8" = "seek 80 absolute-percent";
        "9" = "seek 90 absolute-percent";
        G = "seek 100 absolute-percent";

        L = ''cycle-values loop-file "inf" "no"'';
        f = "cycle fullscreen";
        c = "cycle sub";
        ":" = "cycle osc";

        q = "quit";
      };
    };
  };

  services.kanshi = {
    enable = true;
    profiles = let
      criteria = "Unknown TL140BDXP01-0 0x00000000";
      mode = "2560x1440@120Hz";
    in {
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
            position = "103,939";
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

  wayland.windowManager.sway = let
    wobsock = "$XDG_RUNTIME_DIR/wob.sock";
    mpvsock = "$XDG_RUNTIME_DIR/mpv.sock";
  in {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    extraOptions = [ "--unsupported-gpu" ];
    extraConfigEarly = ''
      include $HOME/.cache/wal/colors-sway
      exec_always rm -f ${wobsock}; mkfifo ${wobsock} && tail -f ${wobsock} | wob -o 0 -b 0 -p 6 -H 28 --background-color "$foreground"CC --bar-color "$background"CC --overflow-background-color "$color1"CC --overflow-bar-color "$background"CC
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
      output."*".bg = "~/.config/wallpaper.* fill";
      # TODO: inhibit idle and floats
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
      } // (foldl' (s: i:
        s // {
          "${modifier}+${toString i}" = "workspace number ${toString i}";
        }) { } (lib.range 0 9)) // (foldl' (s: i:
          s // {
            "${modifier}+Shift+${toString i}" =
              "move container to workspace number ${
                toString i
              }, workspace number ${toString i}";
          }) { } (lib.range 0 9)) //

        {

          "${modifier}+Shift+tab" = "floating toggle";
          "${modifier}+tab" = "focus mode_toggle";

          "${modifier}+r" = ''mode "resize"'';
          "${modifier}+v" = ''mode "move"'';
          "${modifier}+escape" = ''mode "passthrough"'';

          "${modifier}+Shift+q" = "quit";
          "${modifier}+q" = "kill";
          "${modifier}+w" = "kill";

          "${modifier}+Shift+d" = "exec systemctl restart --user kanshi";

          "${modifier}+space" = "exec wofi --show drun";
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
        statusCommand = "~/.scripts/status"; # TODO: write status command
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
        extraConfig = ''
          height 22
        '';
      }];
      input = {
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "disabled";
        };
        "type:pointer" = { accel_profile = "flat"; };
      };
    };
  };
}
