inputs:
{ config, lib, pkgs, ... }:

let cfg = config.local.common; in
with lib; {
  options.local.common.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = mkIf cfg.enable {
    home.stateVersion = "20.09";

    home.packages = with pkgs; [
      trash-cli
      exa
      ripgrep
      fzf
      jq
      wget
      vimv2
      unzip
      poppler_utils
      ffmpeg
      comma
      pywal
      gotop
    ];

    home.file = {
      ".hushlogin" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { text = ""; };
      ".local/lib/python2.7/site-packages/usercustomize.py".source = ./common/usercustomize2.py;
    } // (lib.listToAttrs
      (map
        (n:
          {
            name = ".local/lib/python3.${builtins.toString n}/site-packages/usercustomize.py";
            value.source = ./common/usercustomize3.py;
          })
        (lib.range 7 10)));

    xdg.configFile = {
      "lf/cleaner" = {
        text = ''
          #!${pkgs.bash}/bin/sh
          kitty +kitten icat --transfer-mode file --clear
        '';
        executable = true;
      };
      "helix/themes/base16_terminal_kitty.toml".source = ./common/base16_terminal_kitty.toml;
      "libvirt/libvirt.conf".text = ''uri_default = "qemu:///system"'';
    };

    nix.registry.nixpkgs = {
      from = {
        type = "indirect";
        id = "nixpkgs";
      };
      to = {
        type = "path";
        path = inputs.nixpkgs;
      };
    };

    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      LESS = "-Ri --incsearch";
    };
    programs =
      let
        # source: https://github.com/andreafrancia/trash-cli/issues/107#issuecomment-479241828
        trash-undo = "echo '' | trash-restore 2>/dev/null | sed '$d' | sort -k2,3 -k1,1n | awk 'END {print $1}' | trash-restore >/dev/null 2>&1";
      in
      {
        bat = {
          enable = true;
          config = { style = "plain"; theme = "base16"; };
        };
        direnv = {
          enable = true;
          config = {
            disable_stdin = true;
            warn_timeout = "11037h";
          };
          nix-direnv.enable = true;
        };
        # TODO: add bash and zsh configuration too with the simplest aliases and starship
        # integration (or define generic aliases and merge them into everything?)
        fish = (
          rec {
            shellAbbrs = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin
              {
                copy = "pbcopy";
                paste = "pbpaste";
              } // {
              c = "command";
              da = "direnv allow";
              dr = "direnv reload";
              g = "git";
              nbh = "nix build .";
              nb = "nix build";
              ndh = "nix develop .";
              ndi = "nix develop ~/.infra#";
              nd = "nix develop";
              nfc = "nix flake check";
              nff = "nix flake info";
              nfi = "nix flake init --template github:mtoohey31/templates#";
              nfl = "nix flake lock";
              nflu = "nix flake lock --update-input";
              nf = "nix flake";
              nfu = "nix flake update";
              n = "nix";
              nr = "nix repl";
              nsd = "nix show-derivation";
              ns = "nix shell";
              pcp = "rsync -r --info=progress2";
              rm = "trash";
              se = "sudoedit";
            };
            shellAliases = shellAbbrs // {
              inherit trash-undo;
              ls = "exa -a --icons --group-directories-first";
              lsd = "exa -al --icons --group-directories-first";
              lst = "exa -aT -L 5 --icons --group-directories-first";
              lsta = "exa -aT --icons --group-directories-first";
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
                          cd $dir
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
              gce.body = ''
                set tmp (mktemp)
                gcc -Wall -o "$tmp" "$argv[1]" && "$tmp" $argv[2..]
              '';
              gde.body = ''
                set tmp (mktemp)
                gcc -Wall -g -o "$tmp" $argv && gdb --quiet --args "$tmp" $argv
              '';
              gve.body = ''
                set tmp (mktemp)
                gcc -Wall -g -o "$tmp" $argv && valgrind "$tmp" $argv
              '';
            };
            enable = true;
            shellInit =
              let
                batmanPager = pkgs.writeShellScript "bat-manpager"
                  ''col -bx | bat -l man'';
              in
              ''
                export EDITOR=hx
                export VISUAL=hx
                export PAGER=bat
                export MANPAGER=${batmanPager}
              '';
            loginShellInit = ''
              if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a -z "$TMUX"
                  if test -n "$SSH_CONNECTION"
                      exec tmux
                  else if test -n "$ANDROID_DATA"
                      cat ${config.xdg.cacheHome}/wal/sequences
                      exec tmux
                  end
              end
            '';
            interactiveShellInit = let stty = if pkgs.stdenv.hostPlatform.isDarwin then "/bin/stty" else "stty"; in ''
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

              bind -s -M insert \cf 'set old_tty (${stty} -g); ${stty} sane; lfcd; ${stty} $old_tty; commandline -f repaint'
              bind -s -M insert \cl '${if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/tput reset" else "tput reset"}; test -n "$TMUX" && tmux clear-history; commandline -f repaint'

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
                  cat ${config.xdg.cacheHome}/wal/sequences &
              end

              alias e "$EDITOR"
              abbr e "$EDITOR"
              abbr cat bat
            '' + (builtins.readFile (builtins.fetchurl {
              # TODO: turn this into a flake so I can bind it to the exa version more elegantly
              url = "https://github.com/mtoohey31/lf-exa-icons/releases/download/v${pkgs.exa.version}/icons";
              sha256 = "16h52mm589f9y0y27iwjgrbrk9i34dp4hhi25qz7qpnyx20qrsay";
            }
            ));
          }
        );
        git = {
          enable = true;
          userName = "Matthew Toohey";
          userEmail = "contact@mtoohey.com";
          iniContent = {
            branch = { autosetuprebase = "always"; };
            init = { defaultBranch = "main"; };
          };
          ignores = [ ".direnv/" ];
          aliases = {
            a = "add --verbose";
            aa = "add --all --verbose";
            add = "add --verbose";
            af = "add --force --verbose";
            afhp = "add --force --patch .";
            afp = "add --force --patch";
            ah = "add --verbose .";
            ahp = "add --patch .";
            ap = "add --patch --verbose";
            b = "!git --no-pager branch";
            bd = "branch --delete";
            bdd = "branch --delete --force";
            bm = "branch --move";
            br = "!git branch -m $(git rev-parse --abbrev-ref HEAD)";
            bs = "branch --set-upstream-to";
            bt = "branch --track";
            bv = "!git --no-pager branch -vv";
            c = "commit";
            ca = "commit --amend";
            can = "commit --amend --no-edit";
            canp = "!git commit --amend --no-edit && git push";
            cap = "!git commit --amend && git push";
            cd = "reset --hard HEAD~";
            cm = ''!f() { git commit --message "$*"; }; f'';
            cu = "reset HEAD~";
            d = "diff";
            dh = "diff .";
            dhn = "diff --no-ext-diff .";
            dl = "diff HEAD~ HEAD";
            dln = "diff --no-ext-diff HEAD~ HEAD";
            dlt = "diff --stat HEAD~ HEAD";
            dltn = "diff --no-ext-diff --stat HEAD~ HEAD";
            dn = "diff --no-ext-diff";
            ds = "diff --staged";
            dsn = "diff --no-ext-diff --staged";
            dst = "diff --staged --stat";
            dstn = "diff --no-ext-diff --staged --stat";
            dt = "diff --stat";
            dtn = "diff --no-ext-diff --stat";
            dw = "diff --no-prefix --unified=99999999999999999";
            dwn = "diff --no-ext-diff --no-prefix --unified=99999999999999999";
            e = "rebase";
            ea = "rebase --abort";
            ec = "rebase --continue";
            ei = "rebase --interactive";
            eir = "rebase --interactive --root";
            eirt = "rebase --interactive --root --autostash";
            eit = "rebase --interactive --autostash";
            es = "rebase --skip";
            et = "rebase --autostash";
            f = "fetch";
            fu = "fetch --unshallow";
            g = "reflog";
            i = "init";
            k = "checkout";
            kb = "checkout -b";
            kbf = "checkout -b --force";
            kf = "checkout --force";
            l = "log";
            m = "remote --verbose";
            ma = "remote add";
            mao = "remote add origin";
            mau = "remote add upstream";
            mp = "remote prune";
            mpo = "remote prune origin";
            mr = "remote rename";
            mro = "remote rename origin";
            ms = "remote set-url";
            mso = "remote set-url origin";
            msu = "remote set-url upstream";
            o = "clone --recursive";
            ob = "clone --bare";
            onr = "clone";
            p = "push";
            pf = "push --force";
            pu = "!git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
            puf = "!git push --force --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
            r = "restore";
            rh = "restore .";
            rp = "restore --patch";
            rs = "restore --staged";
            rsh = "restore --staged .";
            rsp = "restore --staged --patch .";
            s = "status --short";
            sh = "status --short .";
            ssh = "!git remote set-url origin $(git remote get-url origin | sed -E 's/^https?:\\/\\/github.com\\//git@github.com:/g')";
            t = "stash push --include-untracked";
            td = "stash drop";
            tl = "stash list";
            tm = ''!f() { git stash push --include-untracked --message "$*"; }; f'';
            tp = "stash pop";
            tpp = "stash push --patch";
            ts = "stash show -p";
            u = "pull";
            unbare = ''!f() { TARGET="$(echo "$1" | sed -E 's/\.git\/?$//')" && mkdir "$TARGET" && cp -r "$1" "$TARGET/.git" && cd "$TARGET" && git config --local --bool core.bare false && git reset --hard; }; f'';
            ur = "pull --rebase";
            urt = "pull --rebase --autostash";
            ut = "pull --autostash";
            w = "worktree";
            wa = "worktree add";
            wm = "worktree move";
            wr = "worktree remove";
            x = "rm";
            xc = "rm --cached";
            xch = "rm --cached .";
            xrc = "rm -r --cached";
            xrch = "rm -r --cached .";
            y = "cherry-pick";
            ya = "cherry-pick --abort";
            yc = "cherry-pick --continue";
          } // (pkgs.lib.optionalAttrs (builtins.hasAttr "copy" config.programs.fish.shellAliases)
            { h = "!git rev-parse HEAD | ${pkgs.gnused}/bin/sed -z 's/\\n$//' | ${config.programs.fish.shellAliases.copy}"; });
        };
        helix = {
          enable = true;
          languages = [{ name = "nix"; auto-format = true; }
            { name = "haskell"; auto-format = true; }];
          settings = {
            # TODO: set black to be the theme's black instead of solid black,
            # see https://github.com/kovidgoyal/kitty/issues/3185
            theme = "base16_terminal_kitty";
            editor = {
              idle-timeout = 0;
              scrolloff = 7;
              line-number = "relative";
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };
              rulers = [ 80 100 120 160 ];
              color-modes = true;
              indent-guides.render = true;
              statusline = {
                left = [
                  "file-name"
                  # TODO: uncomment this once I work on the statusline again
                  # "scope"
                  "spinner"
                ];
                right = [
                  "diagnostics"
                  "selections"
                  "position"
                  "file-encoding"
                  "file-type"
                ];
              };
            };
            keys = rec {
              select = rec {
                G = "goto_last_line";
                M = "match_brackets";
                p = "paste_clipboard_after";
                P = "paste_clipboard_before";
                "A-p" = "paste_after";
                "A-P" = "paste_before";
                y = "yank_main_selection_to_clipboard";
                Y = "yank_joined_to_clipboard";
                "A-y" = "yank";
                c = "change_selection_noyank";
                d = [ y "delete_selection" ];
                "A-d" = "delete_selection";
                R = "replace_selections_with_clipboard";
                "A-R" = "replace_with_yanked";
                Q = ":quit!";
                W = [ ":write" "align_view_center" ];
                Z = ":write-quit";
                "C-w"."|" = [ "vsplit_new" "file_picker" ];
                "C-w".minus = [ "hsplit_new" "file_picker" ];
                "C-w"."_" = [ "hsplit_new" "file_picker" ];
              };
              normal = select // {
                space.m = ":format";
                space.M = ":set-option auto-format false";
                J = [ "extend_to_line_end" "join_selections" ];
              };
            };
          };
        };
        # TODO: get lf working more smoothly with direnv so I don't have to do the q c-f dance
        # TODO: make lfcd remember the position of the file browser on reentry so I don't have to scroll back and forth
        lf = {
          enable = true;
          commands = {
            edit = ''
              ''${{
                  set IFS " "
                  $EDITOR -- "$argv"
                  if test -e "$argv"
                      lf -remote "send $id select \"$argv\""
                  end
              }}
            '';
            mkdir = ''
              &{{
                  set IFS " "
                  mkdir -p -- "$argv"
                  lf -remote "send $id select \"$argv\""
              }}
            '';
            touch = ''
              &{{
                  set IFS " "
                  touch "$argv"
                  lf -remote "send $id select \"$argv\""
              }}
            '';
          };
          extraConfig = ''
            set cleaner ${config.xdg.configHome}/lf/cleaner
          '';
          keybindings = {
            E = "push :edit<space>";
            t = "push :touch<space>";
            "<esc>" = "clear";
            u = "%{{ ${trash-undo} }}";
            D = ''%echo "\"$fx\"" | string join '" "' | xargs trash'';
            r = "reload";
            R = "rename";
            M = "push :mkdir<space>";
            x = ''!unzip "$f"'';
            ge = "bottom";
            gi = "cd ~/.infra";
            gn = "cd ~/notes";
            gr = "cd ~/repos";
          };
          previewer.source = pkgs.writeShellScript "lf-previewer" ''
            ${pkgs.pistol}/bin/pistol "$@"

            # this prevents caching, which is desirable so that previews are
            # redrawn when the window is resized
            exit 1
          '';
          settings = {
            dirfirst = false;
            icons = true;
            promptfmt = ''\033[1;33m%u\033[0m in \033[1;36m%d\033[0m\033[1m%f\033[0m'';
            timefmt = "";
            smartcase = true;
            shell = "fish";
            scrolloff = 7;
          };
        };
        nix-index = {
          enable = true;
          enableFishIntegration = true;
        };
        pistol = {
          enable = true;
          config = {
            "text/*" = "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
            "application/json" = "bat --paging=never --color=always --style=auto --wrap=character --terminal-width=%pistol-extra0% --line-range=1:%pistol-extra1% %pistol-filename%";
            "image/*" = ''sh: if [ -z "$SSH_CONNECTION" ]; then kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% %pistol-filename% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% %pistol-filename%; fi'';
            "video/*" = ''sh: if [ -z "$SSH_CONNECTION" ]; then ffmpeg -ss 0 -i %pistol-filename% -vframes 1 -f image2 pipe:1 | kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% <(ffmpeg -ss 0 -i %pistol-filename% -vframes 1 -f image2 pipe:1); fi'';
            "application/pdf" = ''sh: if [ -z "$SSH_CONNECTION" ]; then pdftoppm -f 1 -l 1 %pistol-filename% -png | kitty +kitten icat --transfer-mode file --place %pistol-extra0%x%pistol-extra1%@%pistol-extra2%x%pistol-extra3% && exit 1; else chafa --format symbols --size %pistol-extra0%x%pistol-extra1% <(pdftoppm -f 1 -l 1 %pistol-filename% -png); fi'';

          };
        };
        readline = {
          enable = true;
          variables.editing-mode = "vi";
          # TODO: figure out why this doesn't clear the scrollback buffer, even
          # though the docs: https://tiswww.cwru.edu/php/chet/readline/readline.html#SEC13
          # say it should
          bindings."\\C-l" = "clear-display";
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
              "$sudo"
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
            aws.symbol = "??? ";
            battery = {
              format = "with [$symbol$percentage]($style) battery ";
              full_symbol = "???";
              charging_symbol = "???";
              discharging_symbol = "???";
            };
            character = {
              success_symbol = "[>](green)";
              error_symbol = "[>](red)";
              vimcmd_symbol = "[<](blue)";
              vimcmd_visual_symbol = "[<](yellow)";
              vimcmd_replace_one_symbol = "[<](cyan)";
              vimcmd_replace_symbol = "[<](cyan)";
            };
            cmd_duration.format = "for [$duration]($style) ";
            conda.symbol = "??? ";
            dart.symbol = "??? ";
            directory.format = "in [$path]($style) ";
            docker_context.symbol = "??? ";
            elixir.symbol = "??? ";
            elm.symbol = "??? ";
            git_branch.symbol = "??? ";
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
            golang.symbol = "??? ";
            hg_branch.symbol = "??? ";
            hostname.format = "on [$hostname]($style) ";
            java.symbol = "??? ";
            julia.symbol = "??? ";
            memory_usage.symbol = "??? ";
            nim.symbol = "??? ";
            nix_shell = {
              format = "in $state ";
              impure_msg = "[??? $name](bold purple)";
              pure_msg = "[??? $name](bold blue)";
            };
            nodejs.symbol = "??? ";
            package = {
              symbol = "??? ";
              style = "bold blue";
            };
            perl.symbol = "??? ";
            php.symbol = "??? ";
            python.symbol = "??? ";
            ruby.symbol = "??? ";
            rust.symbol = "??? ";
            scala.symbol = "??? ";
            shell = {
              format = "[$indicator]($style) ";
              disabled = false;
            };
            shlvl = {
              format = "at depth [$shlvl]($style) ";
              disabled = false;
            };
            sudo = {
              disabled = false;
              format = "with [sudo $symbol]($style) ";
              symbol = "???";
            };
            swift.symbol = "??? ";
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
  };
}
