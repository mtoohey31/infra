{ pkgs, ... }:

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

  services.skhd.skhdConfig = ''
    cmd - b : echo '{"args":[""],"target_arg":"","protocol_version":1}' | ${pkgs.socat}/bin/socat - /private/var/folders/*/*/T/qutebrowser/* || ${pkgs.qutebrowser}/Applications/qutebrowser.app/Contents/MacOS/qutebrowser
  '';
}
