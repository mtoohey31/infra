{ buildGoModule }:

buildGoModule rec {
  pname = "caddy-cloudflare";
  version = "2.5.1";
  src = ./.;
  vendorSha256 = "pYl5J/SJuD5tAGhdtxZxXCtVrN0r6qLRh15Eew/Bc6w=";
}
