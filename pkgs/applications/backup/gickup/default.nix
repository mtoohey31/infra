{ buildGoModule, gickup-src }:

buildGoModule rec {
  pname = "gickup";
  version = src.shortRev;
  src = gickup-src;
  vendorSha256 = "z5JjOTq0BTOHAjMZdLG7O0bLHQTvOer6tWj1UUq2mKE=";
}
