{ config, lib, pkgs, ... }:

let
  monoFontPrefix = "JetBrainsMono";
  monoFont = "${monoFontPrefix} Nerd Font";
in {
  home.packages = with pkgs; [
    nsxiv
    pywal
    mpv # TODO: add configuration

    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ monoFontPrefix ]; })
  ];

  programs = {
    brave = {
      enable = true;
      # TODO: figure out how to add profile sync stuff
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
    extraConfig = "default_border none";
    config = {
      modifier = "Mod4";
      terminal = "${pkgs.kitty}/bin/kitty";
      gaps = {
        inner = 16;
        outer = -16;
      };
      focus = {
        followMouse = true;
        mouseWarping = true;
      };
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
      # TODO: keybinds
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
