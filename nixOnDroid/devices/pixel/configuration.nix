# TODO: set up storage access
# TODO: configure terminal font and other settings
# TODO: set up photo backups

{ ... }:

{
  local.primary-user = {
    hostName = "pixel";
    homeManagerCfg = { ... }: { };
  };
}
