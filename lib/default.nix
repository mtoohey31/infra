with builtins;

rec {
  intSeq = min: max:
    if min <= max then ([ min ] ++ (intSeq (min + 1) max)) else [ ];

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

  mkHomeCfg = { user, username }: {
    imports = (map (roleName: ../userRoles + "/${roleName}.nix")
      (import (../users + "/${user}/roles.nix"))) ++ [
        ../userRoles/common.nix

        (../users + "/${user}/home.nix")
      ];
  };

  mkHomeCfgs = { nixpkgs, home-manager, usernames, systems }:
    foldl' (s: user:
      s // (foldl' (s: username:
        s // (foldl' (s: system:
          s // {
            "${username}-${user}-${system}" =
              home-manager.lib.homeManagerConfiguration {
                inherit username system;
                homeDirectory = if system == "x86_64-darwin" then
                  "/Users/${username}"
                else
                  "/home/${username}";
                configuration = (mkHomeCfg { inherit user username; });
                pkgs = import nixpkgs { inherit system; };
              };
          }) { } systems)) { } usernames)) { } (attrNames (readDir ../users));

  mkHostCfgs = { nixpkgs, home-manager }:
    foldl' (s: hostName:
      s // {
        "${hostName}" = nixpkgs.lib.nixosSystem {
          modules = (map (roleName: ../hostRoles + "/${roleName}.nix")
            (import (../hosts + "/${hostName}/roles.nix"))) ++ [
              ../hostRoles/common.nix
              { networking.hostName = hostName; }

              (../hosts + "/${hostName}/configuration.nix")
              (../hosts + "/${hostName}/hardware-configuration.nix")
              home-manager.nixosModule
            ];
          system = let sysPath = ../hosts + "${hostName}system.nix";
          in if (pathExists sysPath) then import sysPath else "x86_64-linux";
        };
      }) { } (attrNames (readDir ../hosts));
}
