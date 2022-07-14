# TODO: remove this once nixpkgs#174842 or a replacement is merged

{ stdenv }:

stdenv.mkDerivation rec {
  pname = "yabai";
  version = "4.0.1";
  src = builtins.fetchurl {
    url = "https://github.com/koekeishiya/${pname}/releases/download/v${version}/${pname}-v${version}.tar.gz";
    sha256 = "1iahdi7a5b5blqdhws42f1rqmw5w70qkl2xiprrjn1swzc2lynsh";
  };
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out/bin" "$out/share/man/man1"
    cp bin/yabai "$out/bin"
    cp doc/yabai.1 "$out/share/man/man1"
  '';
}
