{ config, pkgs, ... }:

let lib = import ../../../lib { lib = pkgs.lib; }; in
{
  users.users.mtoohey = {
    description = "Matthew Toohey";
    home = "/Users/mtoohey";
    createHome = true;
    shell = pkgs.fish;
  };
  home-manager.users.mtoohey = lib.mkHomeCfg "dailyDriver" pkgs;
  system.activationScripts.users.text = ''
    if [ "$(dscl . -read /Users/mtoohey UserShell)" != 'UserShell: ${pkgs.fish}/bin/fish' ]; then
        dscl . -create '/Users/mtoohey' UserShell '${pkgs.fish}/bin/fish'
    fi
  '';
}
