{ fetchFromGitHub, xdg-desktop-portal-wlr }:

xdg-desktop-portal-wlr.overrideAttrs (oldAttrs: rec {
  version = "c34d09877cb55eb353311b5e85bf50443be9439d";
  src = fetchFromGitHub {
    owner = "emersion";
    repo = oldAttrs.pname;
    rev = version;
    sha256 = "I1/O3CPpbrMWhAN4Gjq7ph7WZ8Tj8xu8hoSbgHqFhXc=";
  };
})
