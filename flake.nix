# TODO: add swapfile to nixos systems

{
  description = "Infrastructure configuration";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-master.url = "nixpkgs/master";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    vimv2 = {
      url = "github:mtoohey31/vimv2";
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
    { self
    , flake-utils
    , nixpkgs
    , nixpkgs-master
    , darwin
    , nixos-hardware
    , home-manager
    , nix-index
    , kmonad
    , helix
    , taskmatter
    , vimv2
    , qbpm
    }:
    let
      lib = import ./lib { lib = nixpkgs.lib; };
      overlays = [
        kmonad.overlay
        taskmatter.overlay
        vimv2.overlay

        # TODO: create nixpkgs PR for this
        (self: super: {
          rPackages = super.rPackages // {
            colorout = super.rPackages.buildRPackage rec {
              name = "colorout";
              src = self.fetchFromGitHub {
                owner = "jalvesaq";
                repo = name;
                rev = "79931fd025a21b86e1643dc8c4e4506ea83e2611";
                sha256 = "5ymRtVdSC+r9A2YBx4W5wOyTpLPWcNDkhX4r6GfzouM=";
              };
            };
          };
        })
        (self: _: { helix = helix.defaultPackage."${self.system}"; })
        (self: _:
          let master = (import nixpkgs-master { inherit (self) system; }); in
          {
            # TODO: remove this once 125e35fda755a29ec9c0f8ee9446a047e18efcf7 is in nixos-unstable
            inherit (master) starship;
          })
        (self: super: {
          qutebrowser = (if self.stdenv.hostPlatform.isDarwin then
            self.stdenv.mkDerivation
              rec {
                pname = "qutebrowser";
                version = "2.5.0";
                sourceRoot = "${pname}.app";
                src = self.fetchurl {
                  url = "https://github.com/qutebrowser/qutebrowser/releases/download/v${version}/${pname}-${version}.dmg";
                  sha256 = "v4SdiXUS+fB4js7yf+YCDD4OGcb/5zeYaXoUwk/WwCs=";
                };
                buildInputs = [ self.undmg ];
                installPhase = ''
                  mkdir -p "$out/Applications/${pname}.app"
                  cp -R . "$out/Applications/${pname}.app"
                  chmod +x "$out/Applications/${pname}.app/Contents/MacOS/${pname}"
                  mkdir "$out/bin"
                  ln -s "$out/Applications/${pname}.app/Contents/MacOS/${pname}" "$out/bin/qutebrowser"
                '';
              } else super.qutebrowser);
        })
        (self: _: { qbpm = qbpm.defaultPackage."${self.system}"; })
        (self: super: rec {
          python3Packages = {
            plover-stroke = self.python3Packages.buildPythonPackage rec {
              pname = "plover_stroke";
              version = "1.0.1";
              src = super.python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "t+ZM0oDEwitFDC1L4due5IxCWEPzJbF3fi27HDyto8Q=";
              };
            };
            rtf-tokenize = self.python3Packages.buildPythonPackage rec {
              pname = "rtf_tokenize";
              version = "1.0.0";
              src = super.python3Packages.fetchPypi {
                inherit pname version;
                sha256 = "XD3zkNAEeb12N8gjv81v37Id3RuWroFUY95+HtOS1gg=";
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
          } // super.python3Packages;
          plover.wayland = super.plover.dev.overridePythonAttrs
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
        })
        (self: super: {
          xdg-desktop-portal-wlr = super.xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: rec {
            version = "c34d09877cb55eb353311b5e85bf50443be9439d";
            src = self.fetchFromGitHub {
              owner = "emersion";
              repo = oldAttrs.pname;
              rev = version;
              sha256 = "I1/O3CPpbrMWhAN4Gjq7ph7WZ8Tj8xu8hoSbgHqFhXc=";
            };
          });
        })
        # TODO: remove this when swaylock-effects gets a new release and is updated in nixpkgs
        (self: super: {
          swaylock-effects = super.swaylock-effects.overrideAttrs (_: {
            src = self.fetchFromGitHub {
              owner = "mortie";
              repo = "swaylock-effects";
              rev = "a8fc557b86e70f2f7a30ca9ff9b3124f89e7f204";
              sha256 = "GN+cxzC11Dk1nN9wVWIyv+rCrg4yaHnCePRYS1c4JTk=";
            };
          });
        })
      ];
    in
    {
      homeManagerConfigurations = lib.mkHomeCfgs {
        inherit nixpkgs overlays home-manager;
        usernames = [ "mtoohey" "tooheys" ];
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      };

      nixosConfigurations = lib.mkHostCfgs {
        inherit nixpkgs overlays nixos-hardware home-manager kmonad;
      };

      darwinConfigurations = lib.mkDarwinCfgs {
        inherit nixpkgs overlays darwin home-manager kmonad;
      };
    } // (flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs { inherit system; }; {
        devShell = mkShell {
          nativeBuildInputs = [
            rnix-lsp
            nixpkgs-fmt
            nix-index.defaultPackage."${system}"
            gnumake
            deadnix
          ];
        };
      }));
}
