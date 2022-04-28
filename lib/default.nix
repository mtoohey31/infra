with builtins;
let self = import ./.; in
rec {
  mapToAttrs = f: list: listToAttrs (map (x: { name = x; value = f x; }) list);

  allowedInsecure = import ./allowed-insecure.nix;
  allowedUnfree = import ./allowed-unfree.nix;

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

  mkHomeCfg = { user, standalone ? false }: { lib, ... }: {
    imports =
      let modulePath = ../homeManager/users + "/${user}/modules.nix"; in
      lib.optionals (pathExists modulePath)
        (map (moduleName: ../homeManager/modules + "/${moduleName}.nix")
          (import modulePath)) ++ [
        ../homeManager/modules/common.nix

        {
          programs.fish.shellInit = ''export INFRA_USER="${user}"'';
          programs.home-manager.enable = standalone;
        }

        (../homeManager/users + "/${user}/home.nix")
      ];
  };

  mkHomeCfgs = { nixpkgs, overlays, flake-inputs, home-manager, usernames, systems }:
    foldl'
      (s: user:
        s // (foldl'
          (s: username:
            s // (foldl'
              (s: system:
                s // {
                  "${username}-${user}-${system}" =
                    home-manager.lib.homeManagerConfiguration rec {
                      configuration = mkHomeCfg { inherit user; standalone = true; };
                      extraSpecialArgs = { inherit flake-inputs; lib = nixpkgs.lib // self; };
                      homeDirectory =
                        if pkgs.stdenv.hostPlatform.isDarwin
                        then "/Users/${username}" else "/home/${username}";
                      pkgs = import nixpkgs { inherit overlays system; };
                      inherit system username;
                    };
                })
              { }
              systems))
          { }
          usernames))
      { }
      (attrNames (readDir ../homeManager/users));

  mkNixOSCfgs = { nixpkgs, overlays, flake-inputs, nixos-hardware, kmonad }:
    mapToAttrs
      (hostName: nixpkgs.lib.nixosSystem rec {
        modules =
          let modulePath = ../nixos/systems + "/${hostName}/modules.nix"; in
          nixpkgs.lib.optionals (pathExists modulePath)
            (map (moduleName: ../nixos/modules + "/${moduleName}.nix")
              (import modulePath)) ++ [
            ../nixos/modules/common.nix

            {
              nixpkgs.overlays = overlays;
              networking.hostName = hostName;
            }

            (../nixos/systems + "/${hostName}/configuration.nix")
            (../nixos/systems + "/${hostName}/hardware-configuration.nix")
          ] ++ (
            let
              hardwareProfilePath = ../nixos/systems + "/${hostName}/hardware-profile.nix";
            in
            nixpkgs.lib.optional (pathExists hardwareProfilePath)
              nixos-hardware.nixosModules."${import hardwareProfilePath}"
          ) ++ (
            let
              kbdPath = ../nixos/systems
              + "/${hostName}/default.kbd";
            in
            nixpkgs.lib.optionals (pathExists kbdPath)
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
        specialArgs = { inherit flake-inputs; lib = nixpkgs.lib // self; };
        system =
          let sysPath = ../nixos/systems + "/${hostName}/system.nix";
          in if (pathExists sysPath) then import sysPath else "x86_64-linux";
      })
      (attrNames (readDir ../nixos/systems));

  mkDarwinCfgs = { nixpkgs, overlays, flake-inputs, darwin, kmonad }:
    mapToAttrs
      (hostName: darwin.lib.darwinSystem rec {
        specialArgs = { inherit flake-inputs; lib = nixpkgs.lib // self; };
        modules =
          let modulePath = ../darwin/systems + "/${hostName}/modules.nix"; in
          nixpkgs.lib.optionals (pathExists modulePath)
            (map (moduleName: ../darwin/modules + "/${moduleName}.nix")
              (import modulePath)) ++ [
            ../darwin/modules/common.nix

            {
              nixpkgs.overlays = overlays;
              networking.hostName = hostName;
            }

            (../darwin/systems + "/${hostName}/configuration.nix")
          ];
        system =
          let sysPath = ../darwin/systems + "/${hostName}/system.nix";
          in if (pathExists sysPath) then import sysPath else "x86_64-darwin";
      })
      (attrNames (readDir ../darwin/systems));
}
