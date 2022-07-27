{ fetchFromGitHub, imagemagick, lib, makeWrapper, pywal, stdenv }:

pywal.overrideAttrs (oldAttrs: {
  version = "3.3.0-dev";
  src = fetchFromGitHub {
    owner = "dylanaraps";
    repo = oldAttrs.pname;
    rev = "236aa48e741ff8d65c4c3826db2813bf2ee6f352";
    sha256 = "La6ErjbGcUbk0D2G1eriu02xei3Ki9bjNme44g4jAF0=";
  };
  patches = [ ];
  buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ makeWrapper ];
  postFixup = oldAttrs.postFixup + ''
    wrapProgram $out/bin/wal \
      --prefix PATH : ${imagemagick}/bin
  '';
  doInstallCheck = false;
} // (lib.optionalAttrs stdenv.hostPlatform.isDarwin {
  prePatch = ''
    substituteInPlace pywal/reload.py --replace 'util.get_pid("kitty")' True
  '';
}))
