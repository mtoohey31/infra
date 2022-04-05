# TODO: make locked git fetches inputs
# TODO: add github actions for formatting and building

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

    helix = {
      # TODO: unpin this once https://github.com/helix-editor/helix/issues/1779 is resolved
      url =
        "github:helix-editor/helix?rev=24352b2729559533948da92098529e59cd6562fd";
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

  outputs = { flake-utils, nixpkgs, nixos-hardware, home-manager, helix
    , taskmatter, qbpm, ... }:
    let
      lib = import ./lib;
      overlays = [
        (self: super: { helix = helix.defaultPackage."${self.system}"; })
        taskmatter.overlay
        (self: super: { qbpm = qbpm.defaultPackage."${self.system}"; })
        # TODO: add plover overlay to use the wayland branch
      ];
    in {
      homeManagerConfigurations = lib.mkHomeCfgs {
        inherit home-manager;
        pkgs = import nixpkgs { inherit overlays; };
        usernames = [ "mtoohey" "tooheys" ];
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      };

      nixosConfigurations = lib.mkHostCfgs {
        inherit nixpkgs overlays nixos-hardware home-manager;
      };

    } // (flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs { inherit overlays system; }; {
        devShell = mkShell { buildInputs = [ rnix-lsp nixfmt ]; };
      }));
}
