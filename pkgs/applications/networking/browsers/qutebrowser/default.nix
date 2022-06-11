{ qutebrowser, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "qutebrowser";
    version = "2.5.1";
    sourceRoot = "${pname}.app";
    src = builtins.fetchurl {
      url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}.dmg";
      sha256 = "1Pda2gzmGgiN6f/0K4sOSUav1HvLTlzrEJd8fT9lgBw=";
    };
    buildInputs = [ undmg ];
    installPhase = ''
      mkdir -p "$out/Applications/${pname}.app"
      cp -R . "$out/Applications/${pname}.app"
      chmod +x "$out/Applications/${pname}.app/Contents/MacOS/${pname}"
      mkdir "$out/bin"
      ln -s "$out/Applications/${pname}.app/Contents/MacOS/${pname}" "$out/bin/${pname}"
    '';
  } else qutebrowser
