{ kitty, stdenv, writeShellScript }:

writeShellScript "kitty-window" (if stdenv.hostPlatform.isDarwin
then ''
  KITTY_SOCKET="/tmp/kitty.$(whoami).sock"
  test -S "$KITTY_SOCKET" && ${kitty}/bin/kitty @ --to "unix:$KITTY_SOCKET" launch --type os-window "$@" || open -a ${kitty}/Applications/kitty.app --args --listen-on "unix:$KITTY_SOCKET" "$@"
'' else ''
  KITTY_SOCKET="$XDG_RUNTIME_DIR/kitty.$(whoami).sock"
  test -S "$KITTY_SOCKET" && ${kitty}/bin/kitty @ --to "unix:$KITTY_SOCKET" launch --type os-window "$@" || ${kitty}/bin/kitty --listen-on "unix:$KITTY_SOCKET" "$@"
'')
