# TODO: add swapfile to nixos systems
# TODO: display active vms in status command if there are any
# TODO: fix clearing the screen in various things:
# - readline in kitty
# - fish and readline in tmux
# - lf and helix (shouldn't do anything)

{
  description = "Infrastructure configuration";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:mtoohey31/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:t184256/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
      inputs.home-manager.follows = "home-manager";
    };

    git-crypt-agessh = {
      url = "github:mtoohey31/git-crypt-agessh";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cogitri = {
      url = "github:Cogitri/cogitri-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    fuzzel = {
      # TODO: update once next release hits nixpkgs
      url = "git+https://codeberg.org/dnkl/fuzzel";
      flake = false;
    };
    g14-patches = {
      url = "git+https://gitlab.com/dragonn/linux-g14?ref=5.17";
      flake = false;
    };
    gemoji = {
      url = "git+https://github.com/github/gemoji";
      flake = false;
    };
    harpoond = {
      url = "github:andreldm/harpoond";
      flake = false;
    };
    helix = {
      url = "github:mtoohey31/helix/feat/widechar-aware-vertical-move";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    nixos-hardware = {
      url = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qbpm = {
      url = "github:pvsr/qbpm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    qutewal = {
      url = "git+https://gitlab.com/jjzmajic/qutewal";
      flake = false;
    };
    uncommitted-go = {
      url = "github:mtoohey31/uncommitted-go";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    vimv2 = {
      url = "github:mtoohey31/vimv2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
  };

  outputs =
    { cogitri
    , darwin
    , git-crypt-agessh
    , home-manager
    , kmonad
    , nixpkgs
    , nix-on-droid
    , self
    , sops-nix
    , uncommitted-go
    , utils
    , vimv2
    , ...
    }@inputs:
    {
      darwinConfigurations.air = darwin.lib.darwinSystem {
        modules = (builtins.attrValues self.darwinModules) ++ [
          {
            nixpkgs.overlays = builtins.attrValues self.overlays;
            networking.hostName = "air";
          }
          (import ./darwin/systems/air/configuration.nix)
        ];
        system = "x86_64-darwin";
      };
      darwinModules = self.modules //
      home-manager.darwinModules //
      (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./darwin/modules/modules.nix)));

      homeManagerModules = (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./homeManager/modules/modules.nix)));

      modules = (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./modules/modules.nix)));

      nixosConfigurations = {
        cloudberry = nixpkgs.lib.nixosSystem {
          modules = (builtins.attrValues self.nixosModules) ++ [
            {
              networking.hostName = "cloudberry";
              nixpkgs.overlays = builtins.attrValues self.overlays;
              sdImage = {
                compressImage = false;
                imageName = "cloudberry-${self.shortRev or "dirty"}.img";
              };
            }
            (import ./nixos/systems/cloudberry/configuration.nix (inputs // self))
            (nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
          ];
          system = "aarch64-linux";
        };
        zephyrus =
          nixpkgs.lib.nixosSystem
            {
              modules = (builtins.attrValues self.nixosModules) ++
              [
                ({ lib, ... }: {
                  networking.hostName = "zephyrus";
                  nixpkgs = {
                    config.allowUnfreePredicate = pkg:
                      builtins.elem (lib.getName pkg) [
                        "bitwig-studio"
                        "cudatoolkit"
                        "nvidia-settings"
                        "nvidia-x11"
                        "osu-lazer"
                        "steam"
                        "steam-original"
                      ];
                    overlays = builtins.attrValues self.overlays;
                  };
                })
                (import ./nixos/systems/zephyrus/configuration.nix (inputs // self))
              ];
              system = "x86_64-linux";
            };
      };
      nixosImages.cloudberry = self.nixosConfigurations.cloudberry.config.system.build.sdImage;
      nixosModules = self.modules //
      home-manager.nixosModules //
      kmonad.nixosModules //
      sops-nix.nixosModules //
      (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./nixos/modules/modules.nix)));

      nixOnDroidConfigurations = {
        pixel = nix-on-droid.lib.nixOnDroidConfiguration rec {
          config = import ./nixOnDroid/devices/pixel/configuration.nix (inputs // self);
          extraModules = (builtins.attrValues self.nixOnDroidModules) ++ [{
            environment.sessionVariables.INFRA_DEVICE = "pixel";
          }];
          pkgs = import nixpkgs {
            overlays = builtins.attrValues self.overlays;
            inherit system;
          };
          system = "aarch64-linux";
        };
      };
      nixOnDroidModules = self.modules //
      (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./nixOnDroid/modules/modules.nix)));

      overlays = {
        default = (_: prev: import ./pkgs inputs prev);

        cogtri = cogitri.overlays.default;
        kmonad = kmonad.overlays.default;
        uncommitted-go = uncommitted-go.overlays.default;
        vimv2 = vimv2.overlay;
      };
    } // (utils.lib.eachDefaultSystem (system:
    let
      pkgs =
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        };
    in
    with pkgs; {
      devShells = {
        default = mkShell {
          # NOTE: some of these packages are included in the common home
          # manager module, but they are also included here in case this is
          # being worked on from another environment
          packages = [
            rnix-lsp
            yaml-language-server
            nixpkgs-fmt
            gnumake
            deadnix
            # TODO: integrate https://github.com/Mic92/nix-index-database
            nix-index

            sops
            rage
            ssh-to-age
            git-crypt-agessh.packages."${system}".default
          ];
        };

        ci = mkShell {
          packages = [
            nixpkgs-fmt
            deadnix
          ];
        };

        go = mkShell { name = "go"; packages = [ go gopls ]; };
        go118 = mkShell { name = "go-1.18"; packages = [ go_1_18 gopls ]; };
        rust = mkShell {
          packages = [ cargo rustc rustfmt rust-analyzer ];
          shellHook = ''
            export RUST_SRC_PATH="${rust.packages.stable.rustPlatform.rustLibSrc}"
          '';
        };
      };

      packages = import ./pkgs inputs (import nixpkgs { inherit system; });
    }));
}
