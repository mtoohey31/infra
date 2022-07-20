inputs: pkgs:
let inherit (pkgs) callPackage; in
rec {
  caddy-cloudflare = callPackage ./servers/caddy { };
  fan2go = callPackage ./os-specific/linux/fan2go {
    fan2go-src = inputs.fan2go;
  };
  fileshelter = callPackage ./servers/web-apps/fileshelter { };
  fuzzel = callPackage ./applications/misc/fuzzel {
    fuzzel-src = inputs.fuzzel;
    inherit (pkgs) fuzzel;
  };
  gickup = callPackage ./applications/backup/gickup {
    gickup-src = inputs.gickup;
  };
  gotop = callPackage ./tools/system/gotop { inherit (pkgs) gotop; };
  gow = callPackage ./development/tools/gow {
    gow-src = inputs.gow;
  };
  harpoond = callPackage ./os-specific/linux/harpoond {
    harpoond-src = inputs.harpoond;
  };
  helix = inputs.helix.packages.${pkgs.system}.default;
  Karabiner-DriverKit-VirtualHIDDevice = callPackage
    ./os-specific/darwin/Karabiner-DriverKit-VirtualHIDDevice
    { Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad + "/c_src/mac/Karabiner-DriverKit-VirtualHIDDevice"; };
  kitty = callPackage ./applications/terminal-emulators/kitty {
    inherit (pkgs) kitty;
  };
  kitty-window = callPackage ./applications/terminal-emulators/kitty-window {
    inherit kitty;
  };
  kmonad-daemon-shim = callPackage ./os-specific/darwin/kmonad-daemon-shim { };
  plover = pkgs.plover // {
    wayland = callPackage ./tools/inputmethods/plover/wayland.nix { };
  };
  python3Packages = pkgs.python3Packages // {
    plover-stroke = callPackage ./development/python-modules/plover-stroke { };
    pywayland_0_4_7 = callPackage ./development/python-modules/pywayland { };
    rtf-tokenize = callPackage ./development/python-modules/rtf-tokenize { };
  };
  pywal = callPackage ./development/python-modules/pywal {
    inherit (pkgs) pywal;
  };
  qbpm = inputs.qbpm.packages.${pkgs.system}.default;
  qutebrowser = callPackage ./applications/networking/browsers/qutebrowser {
    inherit (pkgs) qutebrowser;
  };
  rnix-lsp = inputs.rnix-lsp.defaultPackage.${pkgs.system};
  tinkle = callPackage ./os-specific/darwin/tinkle { };
  yabai = callPackage ./os-specific/darwin/yabai { };
  xcaddy = callPackage ./development/tools/xcaddy { };
  xdg-desktop-portal-wlr = callPackage ./development/libraries/xdg-desktop-portal-wlr {
    inherit (pkgs) xdg-desktop-portal-wlr;
  };
}
