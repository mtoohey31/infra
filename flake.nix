# TODO: make locked git fetches inputs
# TODO: add github actions for formatting and building

{
  description = "Infrastructure configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    nixos-hardware.url = "nixos-hardware";

    home-manager = {
      url = "github:mtoohey31/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, ... }:
    let lib = import ./lib;
    in {
      homeManagerConfigurations = lib.mkHomeCfgs {
        inherit nixpkgs home-manager;
        usernames = [ "mtoohey" "tooheys" ];
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      };

      nixosConfigurations =
        lib.mkHostCfgs { inherit nixpkgs nixos-hardware home-manager; };
    };
}
