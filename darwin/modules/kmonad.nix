_:
{ config, lib, pkgs, ... }:

let
  cfg = config.local.kmonad;
in
with lib; {
  options.local.kmonad.enable = mkOption {
    type = types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.kmonad-default.serviceConfig = {
      EnvironmentVariables.PATH = "${pkgs.kmonad}/bin:${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS:${config.environment.systemPath}";
      KeepAlive = true;
      Nice = -20;
      ProgramArguments = [
        "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim"
        "--input"
        ''iokit-name "Apple Internal Keyboard / Trackpad"''
        (builtins.toString (builtins.toFile "kmonad-default.kbd" ''
          (defcfg
            input (iokit-name "Apple Internal Keyboard / Trackpad")
            output (kext)
            fallthrough true
            allow-cmd false
          )

          ${builtins.readFile ../../default.kbd}
        ''))
      ];
      StandardOutPath = "/Library/Logs/KMonad/default-stdout";
      StandardErrorPath = "/Library/Logs/KMonad/default-stderr";
      RunAtLoad = true;
    };
    system.activationScripts.applications = {
      text = ''
        echo copying dext...
        ${pkgs.rsync}/bin/rsync -a --delete ${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Applications/.Karabiner-VirtualHIDDevice-Manager.app /Applications/.Karabiner-VirtualHIDDevice-Manager.app
        echo copying shim...
        cp ${pkgs.kmonad-daemon-shim}/bin/kmonad-daemon-shim /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
        chmod og= /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
        chown root /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
        echo activating dext...
        /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
        printf '\x1b[0;31mPlease grant Input Monitoring permissions to /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'
      '';
    };
  }
  ;
}
