# TODO: add swapfile to nixos systems
# TODO: display active vms in status command if there are any

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

    git-crypt-agessh = {
      url = "github:mtoohey31/git-crypt-agessh";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    nix-index = {
      url = "github:bennofs/nix-index";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:helix-editor/helix";
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
    yabai = {
      url = "github:koekeishiya/yabai";
      flake = false;
    };
  };

  outputs =
    { cogitri
    , darwin
    , fuzzel
    , git-crypt-agessh
    , harpoond
    , helix
    , home-manager
    , kmonad
    , nix-index
    , nixpkgs
    , qbpm
    , self
    , sops-nix
    , uncommitted-go
    , utils
    , vimv2
    , yabai
    , ...
    }@inputs:
    {
      darwinConfigurations.air = darwin.lib.darwinSystem {
        modules = (builtins.attrValues self.darwinModules) ++ [
          {
            nixpkgs.overlays = builtins.attrValues self.overlays;
            networking.hostName = "air";
          }
          (import ./darwin/systems/air/configuration.nix (inputs // self))
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

      nixosConfigurations.zephyrus =
        nixpkgs.lib.nixosSystem
          {
            modules = (builtins.attrValues self.nixosModules) ++
            [
              ({ lib, ... }: {
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
                networking.hostName = "zephyrus";
              })
              (import ./nixos/systems/zephyrus/configuration.nix (inputs // self))
            ];
            system = "x86_64-linux";
          };
      nixosModules = self.modules //
      home-manager.nixosModules //
      { kmonad = kmonad.nixosModule; } //
      sops-nix.nixosModules //
      (builtins.listToAttrs (map
        (path: {
          name = builtins.baseNameOf path;
          value = import path (inputs // self);
        })
        (import ./nixos/modules/modules.nix)));

      overlays.default = nixpkgs.lib.composeManyExtensions [
        cogitri.overlays.default
        kmonad.overlay
        uncommitted-go.overlays.default
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
        (self: super: { yabai = super.yabai.overrideAttrs (_: {
          src = yabai;
          # TODO: please don't look too close at this :see_no_evil:
          prePatch = ''
            substituteInPlace makefile \
                --replace xcrun 'SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX12.3.sdk /usr/bin/xcrun'
          '';
        }); })
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
              RULES="$(headsetcontrol -u | grep -A1 "SteelSeries Arctis 9")"
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
    } // (utils.lib.eachDefaultSystem (system:
    let pkgs =
      import nixpkgs { inherit system; }; in
    with pkgs; {
      devShells = {
        default = mkShell {
          packages = [
            rnix-lsp
            yaml-language-server
            nixpkgs-fmt
            gnumake
            deadnix

            sops
            rage
            ssh-to-age
            git-crypt-agessh.packages."${system}".default
          ] ++ (lib.optional
            # TODO: get nix-index working on aarch64-linux
            (lib.hasAttr system nix-index.defaultPackage)
            nix-index.defaultPackage."${system}");
        };

        go = mkShell { name = "go"; packages = [ go gopls ]; };
        go118 = mkShell { name = "go-1.18"; packages = [ go_1_18 gopls ]; };
      };
    }));
}
