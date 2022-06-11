{ fuzzel, fuzzel-src }:

fuzzel.overrideAttrs (_: rec {
  version = "1.7.0-dev";
  src = fuzzel-src;
})
