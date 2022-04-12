{ config, lib, pkgs, ... }:

# TODO:
#
# kmonad
# scripts
# check dotfiles repo for any other configs that need to get picked up
# make cursor not tiny

with builtins;
let lib = import ../lib;
in
{
  xdg.configFile."kitty/search".source = fetchTarball {
    url =
      "https://github.com/trygveaa/kitty-kitten-search/archive/8cc3237e6a995b6e7e101cba667fcda5439d96e2.tar.gz";
    sha256 = "0h4zryamysalv80dgdwrlfqanx45xl7llmlmag0limpa3mqs0hs3";
  };

  home.packages = with pkgs; [
    nsxiv
    pywal
    plover.dev
    socat
    qbpm # TODO: add greasemonkey and figure out how to handle bookmarks
    xdg-utils
    kmonad

    rofi # TODO: replace this with a wrapper script because it's only used for qute-bitwarden and won't be available on macos
    keyutils # needed for qute-bitwarden userscript

    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ibm-plex
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # TODO: fix having to force this https://github.com/nix-community/home-manager/issues/1118
  fonts.fontconfig.enable = pkgs.lib.mkForce true;

  xdg.dataFile = (foldl'
    (s: name:
      s // {
        "qutebrowser-profiles/${name}/config/config.py".text = ''
          config.load_autoconfig(False);
          config.source('${config.xdg.configHome}/qutebrowser/config.py')
        '';
        "qutebrowser-profiles/${name}/config/greasemonkey".source =
          config.lib.file.mkOutOfStoreSymlink
            "${config.xdg.configHome}/qutebrowser/greasemonkey";
      })
    { } [ "personal" "gaming" "university" "mod" ]);

  xdg.desktopEntries =
    (if pkgs.stdenv.hostPlatform.isLinux then {
      todoist = {
        name = "Todoist";
        exec = "brave --profile-directory=\"Default\" --app=https://todoist.com";
        terminal = false;
      };
    } else { }) // {
      qbpm = {
        type = "Application";
        name = "qbpm";
        icon = "qutebrowser";
        exec = "qbpm choose %u";
        categories = [ "Network" ];
        terminal = false;
      };
    };

  xdg.mimeApps = {
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

  home.file.Downloads.source = config.lib.file.mkOutOfStoreSymlink config.home.homeDirectory;
  programs = {
    brave = {
      enable = true;
      # TODO: figure out how to add profile sync and add keybindings
    };
    fish = rec {
      shellAbbrs = {
        zth = "zathura --fork";
      };
      shellAliases = shellAbbrs // { nsxiv = "nsxiv -a"; };
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
    qutebrowser = {
      enable = true;
      extraConfig = ''
        ${readFile ./gui/qutebrowser/config.py}
        config.bind('B', 'spawn --userscript ${pkgs.qutebrowser}/share/qutebrowser/userscripts/qute-bitwarden')
      ''; # NOTE: running the command mentioned here might be neccessary: https://github.com/mattydebie/bitwarden-rofi/issues/34#issuecomment-639257565
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

  xdg.configFile."qutebrowser/js".source = ./gui/qutebrowser/js;
  xdg.configFile."qutebrowser/qutewal".source = fetchGit {
    url = "https://gitlab.com/jjzmajic/qutewal";
    rev = "ff878423ab251bf764475ab54b28486b957edfd4";
  };

  xdg.configFile."wal/templates/zathuracolours".source = ./gui/zathuracolours;
}
