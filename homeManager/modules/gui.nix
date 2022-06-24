inputs:
{ config, lib, pkgs, ... }:

let cfg = config.local.gui; in
with lib; {
  options.local.gui.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config =
    let
      qutebrowserPrefix =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "${config.home.homeDirectory}/.qutebrowser"
        else "${config.xdg.configHome}/qutebrowser";
      qutebrowserUserscripts = lib.optionalAttrs config.local.secrets.enable
        (lib.mapAttrs'
          (name: value: {
            name = "${qutebrowserPrefix}/greasemonkey/${name}";
            value = { source = value; };
          })
          config.local.secrets.userscripts);
    in
    mkIf cfg.enable {
      home.packages = with pkgs; [
        socat
        qbpm

        ibm-plex
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ] ++ (lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
        nsxiv
        xdg-utils

        # TODO: debug keyctl link @u @s requirement on reboots (see: https://github.com/mattydebie/bitwarden-rofi/issues/34#issuecomment-639257565)
        keyutils # needed for qute-bitwarden userscript

        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
      ]);

      # TODO: fix having to force this https://github.com/nix-community/home-manager/issues/1118
      fonts.fontconfig.enable = pkgs.lib.mkForce true;

      home.file = {
        Downloads.source = config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory;
      } // (pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin qutebrowserUserscripts);
      xdg = {
        configFile = (pkgs.lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) qutebrowserUserscripts) // {
          "fontconfig/fonts.conf".source = ./gui/fonts.conf;
          "wal/templates/zathuracolours".source = ./gui/zathuracolours;
        };
        dataFile = (builtins.foldl'
          (s: name:
            s // {
              "qutebrowser-profiles/${name}/config/config.py".text = ''
                config.load_autoconfig(False);
                config.source('${qutebrowserPrefix}/config.py')
              '';
              "qutebrowser-profiles/${name}/config/greasemonkey".source =
                config.lib.file.mkOutOfStoreSymlink
                  "${qutebrowserPrefix}/greasemonkey";
            })
          { } [ "personal" "gaming" "university" "mod" ]);
        desktopEntries = pkgs.lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
          qbpm = {
            type = "Application";
            name = "qbpm";
            icon = "qutebrowser";
            exec = "qbpm choose -m \"fuzzel -dmenu\"";
            categories = [ "Network" ];
            terminal = false;
          };
          todoist = {
            name = "Todoist";
            exec = "brave --profile-directory=Default --app=https://todoist.com";
            terminal = false;
          };
        };
        mimeApps = pkgs.lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
          enable = true;
          defaultApplications = {
            "application/pdf" = "org.pwmt.zathura.desktop";
            "image/png" = "nsxiv.desktop";
            "image/jpeg" = "nsxiv.desktop";
            "text/html" = "qbpm.desktop";
            "x-scheme-handler/http" = "qbpm.desktop";
            "x-scheme-handler/https" = "qbpm.desktop";
          };
        };
      };

      programs = {
        brave.enable = (!pkgs.stdenv.hostPlatform.isDarwin); # TODO: get this working on darwin, see nixos/nixpkgs#98853
        fish = rec {
          functions = {
            ssh = {
              body = ''
                if test "$TERM" = "xterm-kitty"
                  TERM=xterm-256color command ssh $argv
                else
                  command ssh $argv
                end
              '';
              wraps = "ssh";
            };
          };
          shellAbbrs = {
            zth = "zathura --fork";
          };
          shellAliases = shellAbbrs // { nsxiv = "nsxiv -a"; };
        };
        kitty = {
          enable = true;
          environment = { SHLVL = "0"; };
          settings = {
            allow_remote_control = true;
            background_opacity = "0.8";
            confirm_os_window_close = 0;
            cursor = "none";
            cursor_blink_interval = 0;
            cursor_text_color = "background";
            enable_audio_bell = false;
            hide_window_decorations = "titlebar-only";
            macos_option_as_alt = true;
            macos_thicken_font = "0.25";
            # TODO: swap this once new os windows can be launched without an
            # existing one on macos properly
            macos_quit_when_last_window_closed = true;
            remember_window_size = false;
            touch_scroll_multiplier = 9;
            update_check_interval = 0;
            window_padding_width = 8;
          };
          keybindings = {
            "shift+enter" = "send_text all \\x1b[13;2u";
            "ctrl+enter" = "send_text all \\x1b[13;5u";
            "ctrl+shift+f" = "launch --location=hsplit --allow-remote-control kitty +kitten ${fetchTarball {
            url = "https://github.com/trygveaa/kitty-kitten-search/archive/8cc3237e6a995b6e7e101cba667fcda5439d96e2.tar.gz";
            sha256 = "0h4zryamysalv80dgdwrlfqanx45xl7llmlmag0limpa3mqs0hs3";
          }}/search.py @active-kitty-window-id";
          };
          extraConfig =
            (if pkgs.stdenv.hostPlatform.isDarwin then ''
              font_family JetBrainsMono Nerd Font Mono Regular
              bold_font JetBrainsMono Nerd Font Mono Bold
              italic_font JetBrainsMono Nerd Font Mono Italic
              bold_italic_font JetBrainsMono Nerd Font Mono Bold Italic

              font_size 16
            '' else ''
              font_family JetBrains Mono Regular Nerd Font Complete
              bold_font JetBrains Mono Bold Nerd Font Complete
              italic_font JetBrains Mono Italic Nerd Font Complete
              bold_italic_font JetBrains Mono Bold Italic Nerd Font Complete

              font_size 12
            '') + ''
              include ${config.xdg.cacheHome}/wal/colors-kitty.conf
            '';
        };
        lf.keybindings.gC = "&kitty -e fish -C lf &>/dev/null &";
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
        # TODO: get config hot-reloading set-up, would probably require a qbpm
        # home-manager module though since there is hot-reload support for
        # normal qutebrowser setups, but it expects the ipc socket to be
        # located at "$XDG_RUNTIME_DIR/qutebrowser/ipc-$(echo -n "$USER" | md5sum | cut -d' ' -f1)"
        # while qbpm places it at "$HOME/.local/share/qutebrowser-profiles/$profile/$(echo -n "$USER" | md5sum | cut -d' ' -f1)"
        qutebrowser = {
          enable = true;
          keyBindings = {
            normal = {
              "D" = "close";
              "so" = "config-source";
              "e" = "edit-url";
              "(" = "jseval --world=main -f ${./gui/qutebrowser/js/slowDown.js}";
              ")" = "jseval --world=main -f ${./gui/qutebrowser/js/speedUp.js}";
              "c-" = "jseval --world=main -f ${./gui/qutebrowser/js/zoomOut.js}";
              "c+" = "jseval --world=main -f ${./gui/qutebrowser/js/zoomIn.js}";
              "<ESC>" = "fake-key <ESC>";
              "<Ctrl-Shift-c>" = "yank selection";
              "v" = "hint all hover";
              "V" = "mode-enter caret";
              "<Ctrl-F>" = "hint --rapid all tab-bg";
              "<Ctrl-e>" = "fake-key <Ctrl-a><Ctrl-c><Ctrl-Shift-e>";
              "o" = "set statusbar.show always;; set-cmd-text -s :open";
              "O" = "set statusbar.show always;; set-cmd-text -s :open -t";
              ":" = "set statusbar.show always;; set-cmd-text :";
              "/" = "set statusbar.show always;; set-cmd-text /";
              "ge" = "scroll-to-perc";
            };
            command = {
              "<Escape>" = "mode-enter normal;; set statusbar.show never";
              "<Return>" = "command-accept;; set statusbar.show never";
            };
          };
          settings =
            let
              command_prefix = [
                "${pkgs.kitty}/bin/kitty"
                "--title"
                "floatme"
                "-o"
                "background_opacity=0.8"
                "-e"
                "fish"
                "-c"
              ];
            in
            {
              auto_save.session = true;
              colors.webpage.preferred_color_scheme = "dark";
              completion.height = "25%";
              content.fullscreen.window = true;
              content.headers.do_not_track = null;
              content.javascript.can_access_clipboard = true;
              downloads.location = {
                directory = "${config.home.homeDirectory}";
                remember = false;
              };
              editor.command = command_prefix ++ [
                "cat '${config.xdg.cacheHome}/wal/sequences' && $EDITOR {file}"
              ];
              fileselect = {
                handler = "external";
                single_file.command = command_prefix ++ [
                  "cat '${config.xdg.cacheHome}/wal/sequences' && lf -command 'map <enter> \${{echo \\\"$f\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
                ];
                multiple_files.command = command_prefix ++ [
                  "cat '${config.xdg.cacheHome}/wal/sequences' && lf -command 'map <enter> \${{echo \\\"$fx\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
                ];
                folder.command = command_prefix ++ [
                  "cat '${config.xdg.cacheHome}/wal/sequences' && lf -command 'set dironly; map <enter> \${{echo \\\"$f\\\" > {}; lf -remote \\\"send $id quit\\\"}}'"
                ];
              };
              fonts = {
                default_size = if pkgs.stdenv.hostPlatform.isDarwin then "16pt" else "12pt";
                default_family = "JetBrainsMono Nerd Font";
              };
              fonts.web.family = {
                standard = "SF Pro Text";
                sans_serif = "SF Pro Text";
                serif = "New York";
                fixed = "JetBrainsMono Nerd Font";
              };
              hints.chars = "asdfghjkl;qwertyuiopzxcvbnm";
              statusbar.show = "never";
              tabs = {
                background = false;
                last_close = "close";
                show = "switching";
                show_switching_delay = 1500;
                title.format = "{current_title}";
              };
              url.start_pages = [ "about:blank" ];
            };
          extraConfig = ''
            config.unbind('<Ctrl-v>')
            config.unbind('<Ctrl-a>')
            config.source('${inputs.qutewal}/qutewal.py')
            config.bind('B', 'spawn --userscript ${pkgs.qutebrowser}/share/qutebrowser/userscripts/qute-bitwarden ${lib.strings.optionalString config.local.wm.enable '' -d "fuzzel -dmenu" -p "fuzzel -dmenu --password --lines 0" ''}')
            import json
            with open("${config.xdg.cacheHome}/wal/colors.json") as file:
                pywal = json.load(file)
                c.url.searchengines = {'DEFAULT':
                                       'https://duckduckgo.com/?q={}&kt=SF+Pro+Text&kj=' +
                                       pywal['colors']['color2'] + '&k7=' +
                                       pywal['special']['background'] + '&kx=' +
                                       pywal['colors']['color1'] + '&k8' +
                                       pywal['special']['foreground'] + '&k9' +
                                       pywal['colors']['color2'] + '&kaa' +
                                       pywal['colors']['color2'] + '&kae=d'}
          '' + (if pkgs.stdenv.hostPlatform.isDarwin then ''
            c.qt.args = ["single-process"]
          '' else ''
          '') + (lib.strings.optionalString (builtins.hasAttr "copy" config.programs.fish.shellAliases) ''
              config.bind('yg', 'spawn --userscript ${pkgs.writeShellScript "qute-yank-git" ''
              set -eo pipefail
              printf "$QUTE_URL" | sed -E 's/^https?:\/\/github.com\//git@github.com:/;s/ (\/[^/]*)\/.*/\1/' | ${config.programs.fish.shellAliases.copy}
            ''}')
          '');
        };
        zathura = {
          enable = true;
          extraConfig = ''
            unmap r
            include ${config.xdg.cacheHome}/wal/zathuracolours
          '';
          options = {
            guioptions = "";
            adjust-open = "width";
            font = "JetBrainsMono Nerd Font 12";
            selection-clipboard = "clipboard";
          };
        };
      };
    };
}
