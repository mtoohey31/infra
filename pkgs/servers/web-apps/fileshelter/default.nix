{ fileshelter }:

fileshelter.overrideAttrs
  (oldAttrs: rec {
    meta = oldAttrs.meta // {
      platforms = [ oldAttrs.meta.platforms ] ++ [ "aarch64-linux" ];
    };
  })
