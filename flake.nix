{
  description = "Infrastructure configuration";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixos-hardware = {
      url = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:mtoohey31/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index = {
      url = "github:bennofs/nix-index";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    taskmatter = {
      url = "github:mtoohey31/taskmatter";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    qbpm = {
      url = "github:pvsr/qbpm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    { flake-utils
    , nixpkgs
    , nixos-hardware
    , home-manager
    , nix-index
    , kmonad
    , helix
    , taskmatter
    , qbpm
    , ...
    }:
    let
      lib = import ./lib;
      overlays = [
        kmonad.overlay
        taskmatter.overlay

        (self: super: { helix = helix.defaultPackage."${self.system}"; })
        (self: super: { qbpm = qbpm.defaultPackage."${self.system}"; })
        # TODO: add plover overlay to use the wayland branch
      ];
    in
    {
      homeManagerConfigurations = lib.mkHomeCfgs {
        inherit home-manager;
        pkgs = import nixpkgs { inherit overlays; };
        usernames = [ "mtoohey" "tooheys" ];
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      };

      nixosConfigurations = lib.mkHostCfgs {
        inherit nixpkgs overlays nixos-hardware home-manager kmonad;
      };

    } // (flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs
        {
          inherit system;
          overlays = [ (self: super: { nix-index = nix-index.defaultPackage."${self.system}"; }) ];
        }; {
        devShell = mkShell { nativeBuildInputs = [ rnix-lsp nixpkgs-fmt nix-index gnumake ]; };
      }));
}
