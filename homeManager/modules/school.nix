{ config, lib, pkgs, ... }:

{
  home.packages = [
    # this is global because I use it as a calculator
    (pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [ ggplot2 ];
    }) # TODO: add configuration

    pkgs.taskmatter
    (pkgs.texlive.combine {
      inherit (pkgs.texlive) scheme-small mdframed needspace zref;
    })
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
    pandoc = {
      enable = true;
      defaults = {
        metadata = {
          author = "Matthew Toohey";
          geometry = [
            "a4paper"
            "margin=2cm"
          ];
          mainfont = "IBM Plex Sans Text";
          monofont = "JetBrainsMono Nerd Font";
          colorlinks = true;
          linestretch = 1.25;
          # '';
        };
        include-in-header = builtins.toFile "pandoc-header" ''
          \usepackage{float}
          \let\origfigure\figure
          \let\endorigfigure\endfigure
          \renewenvironment{figure}[1][2] {
              \expandafter\origfigure\expandafter[H]
          } {
              \endorigfigure
          }

          \usepackage{mdframed}
          \newmdenv[rightline=false,bottomline=false,topline=false,linewidth=2pt,skipabove=\parskip]{customblockquote}
          \renewenvironment{quote}{\begin{customblockquote}\list{}{\rightmargin=0em\leftmargin=0em}%
          \item\relax\ignorespaces}{\unskip\unskip\endlist\end{customblockquote}}

          \newcommand{\N}{\mathbb{N}}
          \newcommand{\Z}{\mathbb{Z}}
          \newcommand{\Q}{\mathbb{Q}}
          \newcommand{\R}{\mathbb{R}}
          \newcommand{\C}{\mathbb{C}}
          \newcommand{\st}{\text{ s.t. }}
          \newcommand{\larr}{\leftarrow}
          \newcommand{\rarr}{\rightarrow}
          \newcommand{\lrarr}{\leftrightarrow}
          \newcommand{\Larr}{\Leftarrow}
          \newcommand{\Rarr}{\Rightarrow}
          \newcommand{\Lrarr}{\Leftrightarrow}
          \newcommand{\sube}{\subseteq}
          \newcommand{\supe}{\superseteq}
        '';
        from = "markdown";
        to = "pdf";
        pdf-engine = "xelatex";
      };
    };
  };
}
