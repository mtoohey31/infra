{ lib, pkgs, ... }:

{
  local.wm.enable = true;

  # TODO: create a primary-user module for darwin and move this stuff there
  users.users.mtoohey = {
    description = "Matthew Toohey";
    home = "/Users/mtoohey";
    createHome = true;
    shell = pkgs.fish;
  };
  home-manager.users.mtoohey = lib.mkHomeCfg { user = "dailyDriver"; };
  system.activationScripts.users.text = ''
    if [ "$(dscl . -read /Users/mtoohey UserShell)" != 'UserShell: ${pkgs.fish}/bin/fish' ]; then
        dscl . -create '/Users/mtoohey' UserShell '${pkgs.fish}/bin/fish'
    fi
  '';
}
