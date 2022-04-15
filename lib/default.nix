{ lib }:

# TODO: clean up all the foldl''s, there must be a cleaner way, look at the builtins some more

with builtins;
rec {
  mkPrimaryUser = { username, groups ? [ "wheel" ] }:
    pkgs: {
      groups."${username}".gid = 1000;
      users."${username}" = {
        isNormalUser = true;
        uid = 1000;
        group = username;
        extraGroups = groups;
        shell = pkgs.fish;
      };
    };

  mkHomeCfg = user: pkgs: {
    imports =
      let modulePath = ../homeManager/users + "/${user}/modules.nix"; in
      lib.optionals (pathExists modulePath)
        (map (moduleName: ../homeManager/modules + "/${moduleName}.nix")
          (import modulePath { inherit pkgs; })) ++ [
        ../homeManager/modules/common.nix

        {
          nixpkgs.config.allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) (import ./unfree.nix);
          nixpkgs.config.permittedInsecurePackages = import ./insecure.nix;
          programs.fish.shellInit = ''export INFRA_USER="${user}"'';
        }

        (../homeManager/users + "/${user}/home.nix")
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
      (attrNames (readDir ../homeManager/users));

  # TODO: check if nixosSystem accepts inputs like darwinSystem does
  mkHostCfgs = { nixpkgs, overlays, nixos-hardware, home-manager, kmonad }:
    foldl'
      (s: hostName:
        s // {
          "${hostName}" = nixpkgs.lib.nixosSystem rec {
            modules =
              let modulePath = ../nixos/systems + "/${hostName}/modules.nix"; in
              lib.optionals (pathExists modulePath)
                (map (moduleName: ../nixos/modules + "/${moduleName}.nix")
                  (import modulePath)) ++ [
                ../nixos/modules/common.nix

                {
                  nixpkgs.config.allowUnfreePredicate = pkg:
                    builtins.elem (lib.getName pkg) (import ./unfree.nix);
                  nixpkgs.config.permittedInsecurePackages = import ./insecure.nix;
                  nixpkgs.overlays = overlays;
                  networking.hostName = hostName;
                }

                (../nixos/systems + "/${hostName}/configuration.nix")
                (../nixos/systems + "/${hostName}/hardware-configuration.nix")
                home-manager.nixosModule
              ] ++ (
                let
                  hardwareProfilePath = ../nixos/systems + "/${hostName}/hardware-profile.nix";
                in
                lib.optional (pathExists hardwareProfilePath)
                  nixos-hardware.nixosModules."${import hardwareProfilePath}"
              ) ++ (
                let
                  kbdPath = ../nixos/systems
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
              let sysPath = ../nixos/systems + "/${hostName}/system.nix";
              in if (pathExists sysPath) then import sysPath else "x86_64-linux";
          };
        })
      { }
      (attrNames (readDir ../nixos/systems));

  mkDarwinCfgs = { nixpkgs, overlays, darwin, home-manager, kmonad }:
    foldl'
      (s: hostName: s // {
        "${hostName}" = darwin.lib.darwinSystem rec {
          modules =
            let modulePath = ../darwin/systems + "/${hostName}/modules.nix"; in
            lib.optionals (pathExists modulePath)
              (map (moduleName: ../darwin/modules + "/${moduleName}.nix")
                (import modulePath)) ++ [
              ../darwin/modules/common.nix

              {
                nixpkgs.config.allowUnfreePredicate = pkg:
                  builtins.elem (lib.getName pkg) (import ./unfree.nix);
                nixpkgs.config.permittedInsecurePackages = import ./insecure.nix;
                nixpkgs.overlays = overlays;
                networking.hostName = hostName;
              }

              (../darwin/systems + "/${hostName}/configuration.nix")
              home-manager.darwinModule
            ];
          system =
            let sysPath = ../darwin/systems + "/${hostName}/system.nix";
            in if (pathExists sysPath) then import sysPath else "x86_64-darwin";
        };
      })
      { }
      (attrNames (readDir ../darwin/systems));
}
