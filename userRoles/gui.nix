{ config, lib, pkgs, ... }:

# TODO:
#
# kmonad
# wob
# mako
# autotiling
# scripts
# check dotfiles repo for any other configs that need to get picked up

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
    mpv # TODO: add configuration
    wofi # TODO: remove after fuzzel is working
    # fuzzel TODO: depends on https://gitlab.gnome.org/GNOME/librsvg/-/issues/856
    flashfocus

    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override {
      fonts = [ "JetBrainsMono" ];
    }) # TODO: reconsider making this a variable
  ];

  programs = {
    # TODO: add qutebrowser and profiles too
    brave = {
      enable = true;
      # TODO: figure out how to add profile sync stuff
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
      # TODO: split the raw config up into the appropriate options
      extraConfig = ''
        # visuals
        font_family JetBrains Mono Regular Nerd Font Complete
        bold_font JetBrains Mono Bold Nerd Font Complete
        italic_font JetBrains Mono Italic Nerd Font Complete
        bold_italic_font JetBrains Mono Bold Italic Nerd Font Complete
        font_size 12
        # TODO: re-enable once this is in the release
        # cursor none
        cursor_text_color background
        cursor_blink_interval 0
        window_padding_width 8
        hide_window_decorations yes
        background_opacity 0.8
        remember_window_size no
        enable_audio_bell no
        include $HOME/.cache/wal/colors-kitty.conf

        # environment
        env SHLVL=0
        env TERM_PROGRAM=kitty

        # no updates
        update_check_interval 0

        # prevent a million kitty processes
        macos_quit_when_last_window_closed yes

        # interaction
        map shift+enter send_text all \x1b[13;2u
        map ctrl+enter send_text all \x1b[13;5u
        touch_scroll_multiplier 9.0
        map ctrl+shift+f launch --location=hsplit --allow-remote-control kitty +kitten search/search.py @active-kitty-window-id
        map ctrl+l combine : clear_terminal scrollback active : send_text normal,application \x0c
      '';
    };
  };

  wayland.windowManager.sway = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    extraOptions = [ "--unsupported-gpu" ];
    extraConfigEarly = "include $HOME/.cache/wal/colors-sway";
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
      export WLR_RENDERER_ALLOW_SOFTWARE=1
    '';
    # TODO: extraPackages = with pkgs; [ swaylock-effects swaybg swayidle sway-contrib.grimshot ];
    extraConfig = ''
      default_border none
      mouse_warping container
      exec_always pkill flashfocus; ${pkgs.flashfocus}/bin/flashfocus --flash-opacity 0.9 --time 200 --ntimepoints 30

      for_window [title="floatme"] floating enable
      for_window [title="Bitwarden"] floating enable
    '';
    config = rec {
      modifier = "Mod4";
      terminal = "${pkgs.kitty}/bin/kitty";
      gaps = {
        inner = 16;
        outer = -16;
      };
      focus = { followMouse = true; };
      seat = { "*" = { hide_cursor = "1000"; }; };
      # TODO: outputs
      output = {
        "*" = { bg = "~/.config/wallpaper.* fill"; };
        "Acer Technologies XV340CK P THQAA0013P00" = {
          scale = "1.25";
          mode = "3440x1440";
          position = "0 0";
        };
      };
      # TODO: inhibit idle and floats
      # TODO: media, apps, and config keybinds: https://github.com/mtoohey31/dotfiles/blob/main/.config/sway/config
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
        }) { } (lib.intSeq 0 9)) // (foldl' (s: i:
          s // {
            "${modifier}+Shift+${toString i}" =
              "move container to workspace number ${
                toString i
              }, workspace number ${toString i}";
          }) { } (lib.intSeq 0 9)) //

        {

          "${modifier}+Shift+tab" = "floating toggle";
          "${modifier}+tab" = "focus mode_toggle";

          "${modifier}+r" = ''mode "resize"'';
          "${modifier}+v" = ''mode "move"'';
          "${modifier}+Escape" = ''mode "passthrough"'';

          "${modifier}+Shift+q" = "quit";
          "${modifier}+q" = "kill";
          "${modifier}+w" = "kill";

          "${modifier}+Shift+d" = "exec systemctl restart --user kanshi";

          "${modifier}+Space" = "exec ${pkgs.wofi}/bin/wofi --show drun";
          "${modifier}+Return" = "exec ${terminal}";
          "${modifier}+Slash" =
            "exec ${terminal} -e ${pkgs.fish}/bin/fish -C lfcd";
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
          font "pango:JetBrainsMono Nerd Font Regular 16px" # TODO: make default font name a variable
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
