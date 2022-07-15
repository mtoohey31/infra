{ stdenv }:

stdenv.mkDerivation {
  pname = "kmonad-daemon-shim";
  version = "0.1.0";
  src = ./.;
  buildPhase = ''
    cc main.c -o kmonad-daemon-shim
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp kmonad-daemon-shim $out/bin
  '';
}
