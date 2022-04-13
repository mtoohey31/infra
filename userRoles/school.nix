{ config, lib, pkgs, ... }:

{
  home.packages = [
    # this is global because I use it as a calculator
    (pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [ ggplot2 ];
    }) # TODO: add configuration

    pkgs.taskmatter
  ];

  programs = {
    fish = rec {
      shellAbbrs.tm = "taskmatter";
      shellAliases = shellAbbrs // {
        R = "R --quiet --save";
      };
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
