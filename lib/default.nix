with builtins;
let self = import ./.; in
rec {
  mapToAttrs = f: list: listToAttrs (map (x: { name = x; value = f x; }) list);

  allowedInsecure = import ./allowed-insecure.nix;
  allowedUnfree = import ./allowed-unfree.nix;

  mkHomeCfg = { user, standalone ? false }: { ... }: {
    imports = (import ../homeManager/modules/modules.nix) ++ [
      {
        programs.fish.shellInit = ''export INFRA_USER="${user}"'';
        programs.home-manager.enable = standalone;
      }

      (../homeManager/users + "/${user}/home.nix")
    ];
  };

  mkHomeCfgs = { nixpkgs, overlays, flake-inputs, home-manager, systems }:
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
                      extraSpecialArgs = {
                        inherit flake-inputs;
                        hostName = null;
                        lib = nixpkgs.lib // self;
                      };
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
          (import ../secrets.nix).usernames))
      { }
      (attrNames (readDir ../homeManager/users));

  mkNixOSCfgs = { nixpkgs, overlays, flake-inputs, kmonad }:
    mapToAttrs
      (hostName: nixpkgs.lib.nixosSystem rec {
        modules = (import ../nixos/modules/modules.nix) ++ [
          {
            nixpkgs.overlays = overlays;
            networking.hostName = hostName;
          }

          (../nixos/systems + "/${hostName}/configuration.nix")
        ] ++ (
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
        modules = (import ../darwin/modules/modules.nix) ++ [
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
