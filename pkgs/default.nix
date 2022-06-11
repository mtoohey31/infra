inputs: pkgs:

with pkgs;

{
  caddy-cloudflare = callPackage ./servers/caddy { };
  fileshelter = callPackage ./servers/web-apps/fileshelter { };
  fuzzel = callPackage ./applications/misc/fuzzel {
    fuzzel-src = inputs.fuzzel;
    inherit (pkgs) fuzzel;
  };
  harpoond = callPackage ./os-specific/linux/harpoond {
    harpoond-src = inputs.harpoond;
  };
  helix = inputs.helix.defaultPackage."${pkgs.system}";
  plover = pkgs.plover // {
    wayland = callPackage ./tools/inputmethods/plover/wayland.nix { };
  };
  python3Packages = pkgs.python3Packages // {
    plover-stroke = callPackage ./development/python-modules/plover-stroke { };
    pywayland_0_4_7 = callPackage ./development/python-modules/pywayland { };
    rtf-tokenize = callPackage ./development/python-modules/rtf-tokenize { };
  };
  qbpm = inputs.qbpm.defaultPackage."${pkgs.system}";
  qutebrowser = callPackage ./applications/networking/browsers/qutebrowser {
    inherit (pkgs) qutebrowser;
  };
  yabai = callPackage ./os-specific/darwin/yabai { };
  xcaddy = callPackage ./development/tools/xcaddy { };
  xdg-desktop-portal-wlr = callPackage ./development/libraries/xdg-desktop-portal-wlr {
    inherit (pkgs) xdg-desktop-portal-wlr;
  };
}
