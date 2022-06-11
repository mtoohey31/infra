{ buildGoModule, fetchFromGitHub, go, makeWrapper }:

(buildGoModule rec {
  pname = "xcaddy";
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "caddyserver";
    repo = "xcaddy";
    rev = "v${version}";
    sha256 = "kB2WyHaln/arvISzVjcgPLHIUC/dCzL9Ub8aEl2xL2c=";
  };
  vendorSha256 = "5n0OWG/grOY3tpr0P0RXxlMOg/ne3fSz30rN0zRi1Tc=";
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram "$out/bin/xcaddy" \
      --prefix PATH : ${go}/bin
  '';
}).overrideAttrs (oldAttrs: {
  disallowedReferences = builtins.filter (pkg: pkg.pname != "go")
    oldAttrs.disallowedReferences;
})
