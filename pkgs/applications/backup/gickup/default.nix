{ buildGoModule, gickup-src }:

buildGoModule rec {
  pname = "gickup";
  version = src.shortRev;
  src = gickup-src;
  vendorSha256 = "cQ8o0eZg2FFfP8tBQnkhPfYhNBN/4RNvef1N2UikBso=";
}
