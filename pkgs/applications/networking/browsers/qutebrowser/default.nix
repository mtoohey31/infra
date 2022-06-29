{ qutebrowser, stdenv, undmg }:

if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation
  rec {
    pname = "qutebrowser";
    version = "2.5.2";
    sourceRoot = "qutebrowser.app";
    src = builtins.fetchurl {
      url = "https://github.com/qutebrowser/qutebrowser/releases/download/v${version}/qutebrowser-${version}.dmg";
      sha256 = "0fdv0vk5x2lq50jhcaxs7gs5fgysfqjrvr1iddl06la8wfnwfllw";
    };
    buildInputs = [ undmg ];
    installPhase = ''
      mkdir -p $out/Applications/qutebrowser.app
      cp -R . $out/Applications/qutebrowser.app
      chmod +x $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser
      mkdir $out/bin
      ln -s $out/Applications/qutebrowser.app/Contents/MacOS/qutebrowser $out/bin/qutebrowser
    '';
  } else qutebrowser
