inputs: pkgs:

with pkgs;

{
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
  gow = callPackage ./development/tools/gow {
    gow-src = inputs.gow;
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
  rnix-lsp = inputs.rnix-lsp.defaultPackage."${pkgs.system}";
  yabai = callPackage ./os-specific/darwin/yabai { };
  xcaddy = callPackage ./development/tools/xcaddy { };
  xdg-desktop-portal-wlr = callPackage ./development/libraries/xdg-desktop-portal-wlr {
    inherit (pkgs) xdg-desktop-portal-wlr;
  };
}
