_:
{ config, lib, pkgs, ... }:

let cfg = config.local.devel;
in
with lib; {
  options.local.devel.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      uncommitted-go
      docker

      rnix-lsp
    ];

    programs = {
      fish = rec {
        shellAbbrs = {
          dc = "docker compose";
          dcd = "docker compose down --remove-orphans";
          dcu = "docker compose up -d --remove-orphans";
          dcdd = "docker compose -f docker-compose-dev.yaml down --remove-orphans";
          dcdu = "docker compose -f docker-compose-dev.yaml up --remove-orphans";
        };
        shellAliases = shellAbbrs;
      };
      # TODO: get this working properly so authentication is already set up,
      # or at least doesn't have issues getting set up
      gh = {
        enable = true;
        enableGitCredentialHelper = true;
        settings = { git_protocol = "ssh"; };
      };
    };

    home.sessionVariables.GOPATH = "${config.home.homeDirectory}/.go";
  };
}
