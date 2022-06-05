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
      url = "github:mtoohey31/nix-on-droid/remove-nix_2_4";
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

      overlays.default = nixpkgs.lib.composeManyExtensions [
        cogitri.overlays.default
        kmonad.overlays.default
        uncommitted-go.overlays.default
        vimv2.overlay

        (self: super: rec {
          arctis-9-udev-rules = self.stdenv.mkDerivation rec {
            pname = "arctis-9-udev-rules";
            version = "0.1.0";
            nativeBuildInputs = [ self.headsetcontrol ];
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p "$out/share/headsetcontrol"
              RULES="$(headsetcontrol -u | grep -A1 "SteelSeries Arctis 9")"
              if test -z "$RULES"; then
                exit 1
              fi
              echo "$RULES" > "$out/share/headsetcontrol/99-arctis-9.rules"
            '';
          };
          caddy-cloudflare = self.callPackage ./pkgs/servers/caddy { };
          fileshelter = super.fileshelter.overrideAttrs
            (oldAttrs: rec {
              meta = oldAttrs.meta // {
                platforms = [ oldAttrs.meta.platforms ] ++ [ "aarch64-linux" ];
              };
            });
          fuzzel = super.fuzzel.overrideAttrs (_: rec {
            version = "HEAD";
            src = inputs.fuzzel;
          });
          harpoond = self.stdenv.mkDerivation rec {
            pname = "harpoond";
            version = "0.1.0";
            src = inputs.harpoond;
            nativeBuildInputs = with self; [ pkg-config libusb ];
            installPhase = ''
              mkdir -p "$out/bin" "$out/lib/udev/rules.d"
              cp harpoond "$out/bin"
              cp 99-harpoond.rules "$out/lib/udev/rules.d"
            '';
          };
          helix = inputs.helix.defaultPackage."${self.system}";
          plover = super.plover // {
            wayland = super.plover.dev.overridePythonAttrs
              (oldAttrs: {
                src = self.fetchFromGitHub {
                  owner = "openstenoproject";
                  repo = "plover";
                  rev = "fd5668a3ad9bd091289dd2e5e8e2c1dec063d51f";
                  sha256 = "2xvcNcJ07q4BIloGHgmxivqGq1BuXwZY2XWPLbFrdXg=";
                };
                propagatedBuildInputs = oldAttrs.propagatedBuildInputs
                ++ [
                  python3Packages.plover-stroke
                  python3Packages.rtf-tokenize
                  python3Packages.pywayland_0_4_7
                ];
                nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
                  self.pkg-config
                ];
                doCheck = false; # TODO: get tests working
                postPatch = ''
                  sed -i /PyQt5/d setup.cfg
                  substituteInPlace plover_build_utils/setup.py \
                    --replace "/usr/share/wayland/wayland.xml" "${self.wayland}/share/wayland/wayland.xml"
                '';
              });
          };
          python3Packages = {
            plover-stroke = self.python3Packages.buildPythonPackage rec {
              pname = "plover_stroke";
              version = "1.0.1";
              src = super.python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "t+ZM0oDEwitFDC1L4due5IxCWEPzJbF3fi27HDyto8Q=";
              };
            };
            pywayland_0_4_7 = super.python3Packages.pywayland.overridePythonAttrs
              (_: rec {
                pname = "pywayland";
                version = "0.4.7";
                src = super.python3Packages.fetchPypi {
                  inherit pname version;
                  sha256 = "0IMNOPTmY22JCHccIVuZxDhVr41cDcKNkx8bp+5h2CU=";
                };
              });
            rtf-tokenize = self.python3Packages.buildPythonPackage rec {
              pname = "rtf_tokenize";
              version = "1.0.0";
              src = super.python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "XD3zkNAEeb12N8gjv81v37Id3RuWroFUY95+HtOS1gg=";
              };
            };
          } // super.python3Packages;
          pywal =
            if self.stdenv.hostPlatform.isDarwin then
              super.pywal.overrideAttrs
                (_: {
                  prePatch = ''
                    substituteInPlace pywal/util.py --replace pidof pgrep
                  '';
                })
            else super.pywal;
          qbpm = inputs.qbpm.defaultPackage."${self.system}";
          qutebrowser = (if self.stdenv.hostPlatform.isDarwin then
            self.stdenv.mkDerivation
              rec {
                pname = "qutebrowser";
                version = "2.5.0";
                sourceRoot = "${pname}.app";
                src = self.fetchurl {
                  url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}.dmg";
                  sha256 = "v4SdiXUS+fB4js7yf+YCDD4OGcb/5zeYaXoUwk/WwCs=";
                };
                buildInputs = [ self.undmg ];
                installPhase = ''
                  mkdir -p "$out/Applications/${pname}.app"
                  cp -R . "$out/Applications/${pname}.app"
                  chmod +x "$out/Applications/${pname}.app/Contents/MacOS/${pname}"
                  mkdir "$out/bin"
                  ln -s "$out/Applications/${pname}.app/Contents/MacOS/${pname}" "$out/bin/${pname}"
                '';
              } else super.qutebrowser);
          xdg-desktop-portal-wlr = super.xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: rec {
            version = "c34d09877cb55eb353311b5e85bf50443be9439d";
            src = self.fetchFromGitHub {
              owner = "emersion";
              repo = oldAttrs.pname;
              rev = version;
              sha256 = "I1/O3CPpbrMWhAN4Gjq7ph7WZ8Tj8xu8hoSbgHqFhXc=";
            };
          });
          xcaddy = (self.buildGoModule rec {
            pname = "xcaddy";
            version = "0.3.0";
            src = self.fetchFromGitHub {
              owner = "caddyserver";
              repo = "xcaddy";
              rev = "v${version}";
              sha256 = "kB2WyHaln/arvISzVjcgPLHIUC/dCzL9Ub8aEl2xL2c=";
            };
            vendorSha256 = "5n0OWG/grOY3tpr0P0RXxlMOg/ne3fSz30rN0zRi1Tc=";
            nativeBuildInputs = [ self.makeWrapper ];
            postInstall = ''
              wrapProgram "$out/bin/xcaddy" \
                --prefix PATH : ${self.go}/bin
            '';
          }).overrideAttrs (oldAttrs: {
            disallowedReferences = builtins.filter (pkg: pkg.pname != "go")
              oldAttrs.disallowedReferences;
          });
          # TODO: remove this once nixpkgs#174842 or a replacement is merged
          yabai = self.stdenv.mkDerivation
            rec {
              pname = "yabai";
              version = "4.0.1";
              src = builtins.fetchurl {
                url = "https://github.com/koekeishiya/${pname}/releases/download/v${version}/${pname}-v${version}.tar.gz";
                sha256 = "1iahdi7a5b5blqdhws42f1rqmw5w70qkl2xiprrjn1swzc2lynsh";
              };
              dontBuild = true;
              installPhase = ''
                ls
                mkdir -p "$out/bin" "$out/share/man/man1"
                cp bin/yabai "$out/bin"
                cp doc/yabai.1 "$out/share/man/man1"
              '';
            };
        })
      ];
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
      };

      packages.xcaddy = xcaddy;
    }));
}
