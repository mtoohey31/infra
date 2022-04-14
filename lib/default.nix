{ lib }:

with builtins;

rec {
  mkPrimaryUser = { username, groups ? [ "wheel" ] }:
    pkgs: {
      groups."${username}".gid = 1000;
      users."${username}" = {
        isNormalUser = true;
        group = username;
        extraGroups = groups;
        shell = pkgs.fish;
      };
    };

  mkHomeCfg = user: pkgs: {
    imports = (map (roleName: ../userRoles + "/${roleName}.nix")
      (import (../users + "/${user}/roles.nix"))) ++ [
      ../userRoles/common.nix

      {
        nixpkgs.overlays = pkgs.overlays;
        programs.fish.shellInit = ''export INFRA_USER="${user}"'';
      }

      (../users + "/${user}/home.nix")
    ];
  };

  mkHomeCfgs = { nixpkgs, overlays, home-manager, usernames, systems }:
    foldl'
      (s: user:
        s // (foldl'
          (s: username:
            s // (foldl'
              (s: system:
                s // {
                  "${username}-${user}-${system}" =
                    home-manager.lib.homeManagerConfiguration rec {
                      inherit system username;
                      pkgs = import nixpkgs { inherit overlays system; };
                      homeDirectory =
                        if pkgs.stdenv.hostPlatform.isDarwin
                        then "/Users/${username}" else "/home/${username}";
                      configuration = mkHomeCfg user pkgs;
                    };
                })
              { }
              systems))
          { }
          usernames))
      { }
      (attrNames (readDir ../users));

  mkHostCfgs = { nixpkgs, overlays, nixos-hardware, home-manager, kmonad }:
    foldl'
      (s: hostName:
        s // {
          "${hostName}" = nixpkgs.lib.nixosSystem rec {
            modules = (map (roleName: ../hostRoles + "/${roleName}.nix")
              (import (../hosts + "/${hostName}/roles.nix"))) ++ [
              ../hostRoles/common.nix

              {
                nixpkgs.overlays = overlays;
                networking.hostName = hostName;
              }

              (../hosts + "/${hostName}/configuration.nix")
              (../hosts + "/${hostName}/hardware-configuration.nix")
              home-manager.nixosModule
            ] ++ (
              let
                hardwareProfilePath = ../hosts
                + "/${hostName}/hardware-profile.nix";
              in
              lib.optional (pathExists hardwareProfilePath)
                nixos-hardware.nixosModules."${import hardwareProfilePath}"
            ) ++ (
              let
                kbdPath = ../hosts
                + "/${hostName}/default.kbd";
              in
              lib.optionals (pathExists kbdPath)
                [
                  kmonad.nixosModule
                  {
                    services.kmonad = {
                      enable = true;
                      configfiles = [ kbdPath ];
                    };
                    systemd.services."kmonad-default" = {
                      enable = true;
                      wantedBy = [ "multi-user.target" ];
                    };
                  }
                ]
            );
            system =
              let sysPath = ../hosts + "/${hostName}/system.nix";
              in if (pathExists sysPath) then import sysPath else "x86_64-linux";
          };
        })
      { }
      (attrNames (readDir ../hosts));
}
