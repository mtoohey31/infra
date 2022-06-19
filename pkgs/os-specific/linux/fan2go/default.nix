{ buildGo118Module, fan2go-src, lm_sensors }:

buildGo118Module rec {
  pname = "fan2go";
  version = src.shortRev;
  src = fan2go-src;
  preBuild = ''
    substituteInPlace vendor/github.com/md14454/gosensors/gosensors.go \
      --replace '// #include <sensors/sensors.h>' '// #include "${lm_sensors}/include/sensors/sensors.h"' \
      --replace '"/etc/sensors3.conf"' '"/nix/store/ag7sxfsw6kqfhchwav1vwmaphiyzmijf-lm-sensors-3.6.0/etc/sensors3.conf"'
  '';
  CGO_LDFLAGS = "-L ${lm_sensors}/lib";
  vendorSha256 = "Cp7daTPxRy2BkgqX4njoi49QDPjSVHZpH3p8Dd+E8Ic=";
}
