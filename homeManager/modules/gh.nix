_:
{ config, lib, ... }:

let cfg = config.local.gh; in
with lib; {
  options.local.gh.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      enableGitCredentialHelper = true;
      settings = { git_protocol = "ssh"; };
    };

    sops.secrets.gh_hosts_file.path = "${config.xdg.configHome}/gh/hosts.yml";
  };
}
