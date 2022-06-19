{ harpoond-src, libusb, pkg-config, stdenv }:

stdenv.mkDerivation rec {
  pname = "harpoond";
  version = src.shortRev;
  src = harpoond-src;
  nativeBuildInputs = [ pkg-config libusb ];
  installPhase = ''
    mkdir -p "$out/bin" "$out/lib/udev/rules.d"
    cp harpoond "$out/bin"
    cp 99-harpoond.rules "$out/lib/udev/rules.d"
  '';
}
