# TODO: add swapfile to nixos systems

{
  description = "Infrastructure configuration";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-master.url = "nixpkgs/master";
    home-manager = {
      url = "github:mtoohey31/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
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
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    nix-index = {
      url = "github:bennofs/nix-index";
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
    vimv2 = {
      url = "github:mtoohey31/vimv2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
  };

  outputs =
    { utils
    , nixpkgs
    , nixpkgs-master
    , home-manager
    , darwin
    , nixos-hardware
    , nix-index
    , cogitri
    , fuzzel
    , harpoond
    , helix
    , kmonad
    , qbpm
    , vimv2
    , ...
    }@flake-inputs:
    let
      lib = import ./lib;
      overlays = [
        cogitri.overlays.default
        kmonad.overlay
        vimv2.overlay

        (_: super: {
          fuzzel = super.fuzzel.overrideAttrs (_: rec {
            version = "HEAD";
            src = fuzzel;
          });
        })
        (self: _: {
          harpoond = self.stdenv.mkDerivation rec {
            pname = "harpoond";
            version = "0.1.0";
            src = harpoond;
            nativeBuildInputs = with self; [ pkg-config libusb ];
            installPhase = ''
              mkdir -p "$out/bin" "$out/lib/udev/rules.d"
              cp harpoond "$out/bin"
              cp 99-harpoond.rules "$out/lib/udev/rules.d"
            '';
          };
        })
        (self: _: { helix = helix.defaultPackage."${self.system}"; })
        # TODO: remove this once 125e35fda755a29ec9c0f8ee9446a047e18efcf7 is in nixos-unstable
        (self: _: { inherit (import nixpkgs-master { inherit (self) system; }) starship; })
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
        (self: _: {
          arctis-9-udev-rules = self.stdenv.mkDerivation rec {
            pname = "arctis-9-udev-rules";
            version = "0.1.0";
            nativeBuildInputs = [ self.headsetcontrol ];
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p "$out/share/headsetcontrol"
              RULES="$(headsetcontrol -u | grep -A1 "SteelSeries Arctis 9" | tail -n1)"
              if test -z "$RULES"; then
                exit 1
              fi
              echo "$RULES" > "$out/share/headsetcontrol/99-arctis-9.rules"
            '';
          };
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
      ];
    in
    {
      homeManagerConfigurations = lib.mkHomeCfgs {
        inherit nixpkgs overlays flake-inputs home-manager;
        usernames = [ "mtoohey" "tooheys" ];
        systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      };

      nixosConfigurations = lib.mkNixOSCfgs {
        inherit nixpkgs overlays flake-inputs nixos-hardware kmonad;
      };

      darwinConfigurations = lib.mkDarwinCfgs {
        inherit nixpkgs overlays flake-inputs darwin kmonad;
      };
    } // (utils.lib.eachDefaultSystem (system:
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
