{ config, pkgs, ... }:

{
  local = {
    primary-user.homeManagerCfg = { ... }: {
      local = {
        devel.enable = true;
        gh.enable = true;
        gui.enable = true;
        music.enable = true;
        sops.enable = true;
        ssh = { inherit (config.networking) hostName; };
      };
    };
    wm.enable = true;
  };

  local.kmonad.enable = true;

  services.skhd.skhdConfig = ''
    cmd - b : echo '{"args":[""],"target_arg":"","protocol_version":1}' | ${pkgs.socat}/bin/socat - /private/var/folders/*/*/T/qutebrowser/* || ${pkgs.qutebrowser}/Applications/qutebrowser.app/Contents/MacOS/qutebrowser
  '';
}
