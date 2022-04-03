{ config, lib, pkgs, ... }:

{
  home.stateVersion = "21.11";

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "discord" ];

  home.packages = with pkgs; [ trash-cli exa ripgrep fzf wget gotop ];

  xdg.configFile."lf/cleaner" = {
    text = ''
      #!${pkgs.bash}/bin/sh
      kitty +kitten icat --transfer-mode file --clear
    '';
    executable = true;
  };

  programs = {
    home-manager.enable = pkgs.stdenv.hostPlatform.isDarwin;

    bat = {
      enable = true;
      config = { theme = "base16"; };
    };
    fish = (let
      abbrsAndAliases = ((if pkgs.stdenv.hostPlatform.isDarwin then {
        copy = "pbcopy";
        paste = "pbpaste";
      } else {
        copy = "wl-copy";
        paste = "wl-paste";
      }) // {
        # TODO: some of these are dev and personal only
        dc = "docker compose";
        dcu = "docker compose up -d --remove-orphans";
        dcd = "docker compose down --remove-orphans";
        dcdu = "docker compose -f docker-compose-dev.yaml up --remove-orphans";
        dcdd =
          "docker compose -f docker-compose-dev.yaml down --remove-orphans";
        e = "$EDITOR";
        g = "git";
        hi = "himalaya";
        pcp = "rsync -r --info=progress2";
        rm = "trash";
        se = "sudoedit";
        tm = "taskmatter";
        zth = "zathura --fork";
      });
    in {
      shellAbbrs = abbrsAndAliases // { };
      shellAliases = abbrsAndAliases // {
        # source: https://github.com/andreafrancia/trash-cli/issues/107#issuecomment-479241828
        trash-undo =
          "echo '' | trash-restore 2>/dev/null | sed '$d' | sort -k2,3 -k1,1n | awk 'END {print $1}' | trash-restore >/dev/null 2>&1";
        R = "R --quiet --save";
        python3 = "python3 -q";
        ls = "exa -a --icons --group-directories-first";
        lsd = "exa -al --icons --group-directories-first";
        lst = "exa -aT -L 5 --icons --group-directories-first";
        lsta = "exa -aT --icons --group-directories-first";
        nsxiv = "nsxiv -a";
      };
      functions = {
        lfcd = {
          body = ''
            set tmp (mktemp)
            lf -last-dir-path=$tmp $argv
            if test -f "$tmp"
                set dir (cat $tmp)
                rm -f $tmp
                if test -d "$dir"
                    if test "$dir" != (pwd)
                        cd $dir
                    end
                end
            end
          '';
          wraps = "lf";
        };
        mv = {
          body = ''
            if test (count $argv) -ge 2 -a ! -d "$argv[-1]"
                trash "$argv[-1]" 2>/dev/null
            end
            command mv $argv
          '';
          wraps = "mv";
        };
        # TODO: figure out how to determine this at build time
        python = {
          body = ''
            # Intelligently determines which startup silencing method to use by testing paths of python instances
            if test (command -v python2) -a (realpath (command -v python)) = (realpath (command -v python2))
                python2 $argv
            else if test (command -v python3) -a (realpath (command -v python)) = (realpath (command -v python3))
                python3 $argv
            else
                eval (command -v python) $argv
            end
          '';
          wraps = "python";
        };
        python2 = {
          body = ''
            if test -z "$argv"
                eval (command -v python2) -i -c "''''"
            else
                eval (command -v python2) $argv
            end
          '';
          wraps = "python2";
        };
        gce = {
          body = ''
            set tmp (mktemp)
            gcc -Wall -o "$tmp" "$argv[1]" && "$tmp" $argv[2..]
          '';
        };
        gde = {
          body = ''
            set tmp (mktemp)
            gcc -Wall -g -o "$tmp" $argv && gdb --quiet --args "$tmp" $argv
          '';
        };
        gve = {
          body = ''
            set tmp (mktemp)
            gcc -Wall -g -o "$tmp" $argv && valgrind "$tmp" $argv
          '';
        };
        music = {
          body = ''
            if tmux has-session -t music &>/dev/null
                tmux attach -t music
            else
                tmux new-session -d -s music -c ~/music fish -C "mpv --shuffle --loop-playlist --no-audio-display --volume=40 --input-ipc-server=/tmp/mpv-socket ."
            end
          '';
        };
      };
      enable = true;
      shellInit = ''
        export EDITOR=kak
        export VISUAL="$EDITOR"
        export PAGER="bat --plain"
        export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      '';
      # TODO: this section's sway branch should be gui only
      loginShellInit = ''
        if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$TMUX"
            if test -n "$SSH_CONNECTION" -o -f /.dockerenv && status --is-interactive
                exec tmux
            else if test -n "$TERMUX_VERSION"
                cat ~/.cache/wal/sequences
                exec tmux
            else
                exec sway
            end
        end
      '';
      interactiveShellInit = ''
        fish_vi_key_bindings

        # TODO: make pasting work in visual mode
        # TODO: make d and x keys work with this
        bind -s p 'commandline -C (math (commandline -C) + 1); fish_clipboard_paste; commandline -f backward-char repaint-mode'
        bind -s P 'fish_clipboard_paste; commandline -f repaint-mode'
        bind -s -M visual -m default y 'fish_clipboard_copy; commandline -f swap-selection-start-stop end-selection repaint-mode'

        bind -s -M visual e forward-single-char forward-word backward-char
        bind -s -M visual E forward-bigword backward-char

        # bind -s -M normal V beginning-of-line begin-selection end-of-line
        # bind -s -M normal yy 'commandline -f kill-whole-line; fish_clipboard_copy'

        bind -s -M insert \cf 'set old_tty (stty -g); stty sane; lfcd; stty $old_tty; commandline -f repaint'

        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_replace_one underscore

        set -U fish_color_autosuggestion brblack
        set -U fish_color_cancel -r
        set -U fish_color_command brgreen
        set -U fish_color_comment brmagenta
        set -U fish_color_cwd green
        set -U fish_color_cwd_root red
        set -U fish_color_end brmagenta
        set -U fish_color_error brred
        set -U fish_color_escape brcyan
        set -U fish_color_history_current --bold
        set -U fish_color_host normal
        set -U fish_color_match --background=brblue
        set -U fish_color_normal normal
        set -U fish_color_operator cyan
        set -U fish_color_param brblue
        set -U fish_color_quote yellow
        set -U fish_color_redirection bryellow
        set -U fish_color_search_match bryellow '--background=brblack'
        set -U fish_color_selection white --bold '--background=brblack'
        set -U fish_color_status red
        set -U fish_color_user brgreen
        set -U fish_color_valid_path --underline
        set -U fish_pager_color_completion normal
        set -U fish_pager_color_description yellow
        set -U fish_pager_color_prefix white --bold --underline
        set -U fish_pager_color_progress brwhite '--background=cyan'

        set fish_greeting

        if test -z "$SSH_CONNECTION" -a -z "$TMUX"
            cat ~/.cache/wal/sequences
        end
      '';
    });
    kakoune = {
      enable = true;
      config = {
        hooks = [{
          name = "WinCreate";
          option = ".*";
          commands = "kakboard-enable";
        }];
        keyMappings = [
          {
            mode = "normal";
            key = "/";
            effect = "/(?i)";
          }
          {
            mode = "insert";
            key = "<c-backspace>";
            effect = "<a-;>:exec -draft \\;Bd<ret>";
          }
        ];
        numberLines = {
          enable = true;
          relative = true;
          highlightCursor = true;
          separator = "' '";
        };
        scrollOff = {
          lines = 7;
          columns = 20;
        };
        wrapLines = {
          enable = true;
          word = true;
          indent = true;
        };
      };
      extraConfig = ''
        set-face global comment grey
        set-face global LineNumbers comment
        set-face global LineNumberCursor red
        set-face global LineNumbersWrapped black
        set-face global BufferPadding black

        # TODO: get these enabled
        # lsp-enable
        # lsp-inlay-diagnostics-enable global
        # lsp-inline-diagnostics-enable global
        # require-module auto-pairs
        # set-option global auto_pairs ( ) { } [ ] '"' '"' "'" "'" ` `
      '';
      plugins = with pkgs.kakounePlugins; [
        kak-lsp # TODO: make this and its configuration and servers dev stuff only
        kakoune-state-save
        kakboard
        auto-pairs-kak
        # TODO: surround-kak
      ];
    };
    # TODO: add icons
    lf = {
      enable = true;
      commands = {
        touch = ''
          &{{
              set IFS " "
              touch "$argv"
              lf -remote "send $id select \"$argv\""
          }}
        '';
        mkdir = ''
          &{{
              set IFS " "
              mkdir -p -- "$argv"
              lf -remote "send $id select \"$argv\""
          }}
        '';
      };
      extraConfig = ''
        set cleaner ~/.config/lf/cleaner
      '';
      keybindings = {
        t = "push :touch<space>";
        "<esc>" = "clear";
        # source: https://github.com/andreafrancia/trash-cli/issues/107#issuecomment-479241828
        # TODO: make this shell string a common variable
        u =
          "%{{ echo '' | trash-restore 2>/dev/null | sed '$d' | sort -k2,3 -k1,1n | awk 'END {print $1}' | trash-restore >/dev/null 2>&1 }}";
        D = ''%echo "\"$fx\"" | string join '" "' | xargs trash'';
        r = "reload";
        R = "rename";
        M = "push :mkdir<space>";
        x = ''!unzip "$f"'';
        c = ''
          ''${{
              set IFS " "
              set n 1
              while test -e "card$n.md"
                  set n (math $n + 1)
              end
              $EDITOR -c "startinsert" "card$n.md" && lf -remote "send $id select \"card$n.md\""
          }}
        '';
      };
      previewer = { source = "${pkgs.pistol}/bin/pistol"; };
      settings = {
        icons = true;
        smartcase = true;
        shell = "fish";
        scrolloff = 7;
      };
    };
    # TODO: check if I need bat stuff cause of new default configs
    pistol = {
      enable = true;
      config = {
        "image/*" = ''
          sh: if [ -z "$SSH_CONNECTION" ] || [ -f "/.dockerenv" ]; then kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% %pistol-filename% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% %pistol-filename%; fi'';
        "video/*" = ''
          sh: if [ -z "$SSH_CONNECTION" ] || [ -f "/.dockerenv" ]; then ffmpeg -ss 0 -i %pistol-filename% -vframes 1 -f image2 pipe:1 | kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% <(ffmpeg -ss 0 -i %pistol-filename% -vframes 1 -f image2 pipe:1); fi'';
        "application/pdf" = ''
          sh: if [ -z "$SSH_CONNECTION" ] || [ -f "/.dockerenv" ]; then pdftoppm -f 1 -l 1 %pistol-filename% -png | kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% <(pdftoppm -f 1 -l 1 %pistol-filename% -png); fi'';

      };
    };
    starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$kubernetes"
          "$directory"
          "$shlvl"
          "$git_branch"
          "$git_commit"
          "$git_state"
          "$git_status"
          "$hg_branch"
          "$docker_context"
          "$package"
          "$cmake"
          "$dart"
          "$dotnet"
          "$elixir"
          "$elm"
          "$erlang"
          "$golang"
          "$helm"
          "$java"
          "$julia"
          "$kotlin"
          "$nim"
          "$nodejs"
          "$ocaml"
          "$perl"
          "$php"
          "$purescript"
          "$python"
          "$ruby"
          "$rust"
          "$scala"
          "$swift"
          "$terraform"
          "$vagrant"
          "$zig"
          "$nix_shell"
          "$conda"
          "$memory_usage"
          "$aws"
          "$gcloud"
          "$openstack"
          "$env_var"
          "$crystal"
          "$custom"
          "$cmd_duration"
          "$lua"
          "$battery"
          "$line_break"
          "$jobs"
          "$time"
          "$status"
          "$shell"
          "$character"
        ];
        aws.symbol = " ";
        battery = {
          format = "with [$symbol$percentage]($style) battery ";
          full_symbol = "";
          charging_symbol = "";
          discharging_symbol = "";
        };
        character = {
          success_symbol = "[>](blue)";
          error_symbol = "[>](red)";
          vicmd_symbol = "[<](green)";
        };
        cmd_duration.format = "for [$duration]($style) ";
        conda.symbol = " ";
        custom.docker = {
          format = "inside [ ]($style) ";
          when = "test -f /.dockerenv";
        };
        custom.updates = {
          format = "with [$output]($style) updates ";
          shell = "${pkgs.bash}/bin/sh";
          command = "cat /tmp/num_updates";
          when = ''
            if test $(uname) = "Darwin"; then
              update_indicator_path="$HOME/Library/Logs/Homebrew"
              update_command="nohup /bin/sh -c \"brew update > /dev/null 2>&1 && brew outdated | wc -l | awk '{ \\\$1 = \\\$1; print }' > /tmp/num_updates\" &"
            else
              . /etc/os-release && case "$ID" in
                arch)
                  command -v checkupdates > /dev/null 2>&1 || exit 1
                  update_indicator_path="/var/log/pacman.log"
                  update_command="nohup checkupdates | wc -l > /tmp/num_updates &";;
                alpine)
                  update_indicator_path="/var/cache/apk"
                  update_command="nohup /bin/sh -c \"echo \\\$((\\\$(apk upgrade --simulate | wc -l) - 1)) > /tmp/num_updates\" &";;
                *)
                  exit 1;;
              esac
            fi
            if ! test -e /tmp/num_updates || test -z "$(cat /tmp/num_updates)" || test "$(date -r /tmp/num_updates '+%s')" -lt $(($(date '+%s') - 14400)) || test "$(date -r /tmp/num_updates '+%s')" -lt "$(date -r "$update_indicator_path" '+%s')"; then
              eval "$update_command" > /dev/null 2>&1
            fi
            test "$(cat /tmp/num_updates)" -ge 25
          '';
        };
        dart.symbol = " ";
        directory = {
          format = "in [$path]($style) ";
          read_only = " ";
        };
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        git_branch.symbol = " ";
        git_commit.format = "at [$hash]($style) [$tag]($style)";
        git_status = {
          format = "(with [$all_status$ahead_behind]($style) )";
          conflicted = "UU";
          ahead = "A";
          behind = "B";
          diverged = "V";
          untracked = "U";
          stashed = "T";
          modified = "M";
          staged = "S";
          renamed = "R";
          deleted = "D";
        };
        golang.symbol = " ";
        hg_branch.symbol = " ";
        hostname.format = "on [$hostname]($style) ";
        java.symbol = " ";
        julia.symbol = " ";
        memory_usage.symbol = " ";
        nim.symbol = " ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        package = {
          symbol = " ";
          style = "bold blue";
        };
        perl.symbol = " ";
        php.symbol = " ";
        python.symbol = " ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        shell = {
          format = "[$indicator]($style) ";
          disabled = false;
        };
        shlvl = {
          format = "at depth [$shlvl]($style) ";
          disabled = false;
        };
        swift.symbol = "ﯣ ";
        username = {
          show_always = true;
          format = "[$user]($style) ";
        };
      };
    };
    tmux = {
      enable = true;
      sensibleOnTop = false;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      escapeTime = 0;
      extraConfig = ''
        set-option -g mouse on
        set-option -sg escape-time 0
        set-option -g status off

        bind -r _ split-window -v
        bind -r - split-window -v
        bind -r | split-window -h

        set -g pane-border-style 'fg=color7,bg=color0'
        set -g pane-active-border-style 'fg=color1,bg=color0'

        set-option -ga terminal-overrides ",alacritty:Tc,xterm-kitty:Tc,xterm-256color:Tc"
      '';
    };
  };
}
