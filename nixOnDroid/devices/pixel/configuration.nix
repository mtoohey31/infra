# TODO: configure terminal font and other settings
# TODO: set up photo backups

{ lib, pkgs, ... }:

{
  environment.packages = [ pkgs.ncurses ];

  local.primary-user = {
    hostName = "pixel";
    homeManagerCfg = { config, ... }: {
      home.file = builtins.listToAttrs (map
        (d: {
          name = lib.strings.toLower d;
          value = {
            source = config.lib.file.mkOutOfStoreSymlink ("/storage/emulated/0/" + d);
          };
        }) [ "DCIM" "Download" "Music" ]);
      programs.git.extraConfig.safe.directory = "/storage/emulated/0/Music";
    };
  };
}
