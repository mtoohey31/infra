# TODO: make locked git fetches inputs
# TODO: add github actions for formatting and building

{
  description = "Infrastructure configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nixos-hardware = {
      url = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:mtoohey31/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { nixpkgs, nixos-hardware, home-manager, taskmatter, qbpm, ... }:
    let
      lib = import ./lib;
      overlays = [
        taskmatter.overlay
        (self: super: { qbpm = qbpm.defaultPackage."${self.system}"; })
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
    };
}
