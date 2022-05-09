{ ... }: {
  local = {
    devel.enable = true;
    gui.enable = true;
  };

  programs.git.ignores = [ ".envrc" ];
}
