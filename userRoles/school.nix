{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.taskmatter ];

  programs = {
    fish = rec {
      shellAbbrs.tm = "taskmatter";
      shellAliases = shellAbbrs;

    };
    lf.keybindings.c = ''
      ''${{
          set IFS " "
          set n 1
          while test -e "card$n.md"
              set n (math $n + 1)
          end
          $EDITOR "card$n.md" && test -e "card$n.md" && lf -remote "send $id select \"card$n.md\""
      }}
    '';
  };
}
