{ fuzzel, fuzzel-src }:

fuzzel.overrideAttrs (_: rec {
  version = src.shortRev;
  src = fuzzel-src;
})
