_:
{ ... }:

{
  local = {
    primary-user.homeManagerCfg = { ... }: {
      local = {
        devel.enable = true;
        gui.enable = true;
        music.enable = true;
        ssh.hostName = "air";
      };
    };
    wm.enable = true;
  };
}
