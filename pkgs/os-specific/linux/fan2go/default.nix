{ buildGo118Module, fan2go-src, lm_sensors }:

buildGo118Module rec {
  pname = "fan2go";
  version = src.shortRev;
  src = fan2go-src;
  preBuild = ''
    substituteInPlace vendor/github.com/md14454/gosensors/gosensors.go \
      --replace '"/etc/sensors3.conf"' '"${lm_sensors}/etc/sensors3.conf"'
  '';
  CGO_CFLAGS = "-I ${lm_sensors}/include";
  CGO_LDFLAGS = "-L ${lm_sensors}/lib";
  vendorSha256 = "FvgA6L4qrOBRMa+q4omlrwauJcFnJfmQVycrP1LN8jc=";
}
