{ stdenv, undmg }:

stdenv.mkDerivation rec {
  pname = "tinkle";
  version = "2.1.0";
  src = builtins.fetchurl {
    url = "https://github.com/pqrs-org/Tinkle/releases/download/v${version}/Tinkle-${version}.dmg";
    sha256 = "0rh01lc9gkjymv5lrhjdabjplqkqmzyr2mpy9q9aykzfiij1qzy4";
  };
  buildInputs = [ undmg ];
  sourceRoot = "Tinkle.app";
  installPhase = ''
    mkdir -p $out/Applications/Tinkle.app
    cp -r . $out/Applications/Tinkle.app
  '';
}
