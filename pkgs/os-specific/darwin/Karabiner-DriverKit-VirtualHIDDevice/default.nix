{ cpio, Karabiner-DriverKit-VirtualHIDDevice-src, stdenv, xar }:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = "1.15.0";
  src = Karabiner-DriverKit-VirtualHIDDevice-src + "/dist/Karabiner-DriverKit-VirtualHIDDevice-1.15.0.pkg";
  buildInputs = [ cpio xar ];
  unpackPhase = ''
    xar -xf $src
    mv Payload Payload.gz
    gzip -d Payload.gz
    mkdir extracted && cd extracted && cpio -i < ../Payload
  '';
  dontBuild = true;
  installPhase = ''
    cp -r . $out
  '';
}
