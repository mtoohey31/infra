{ pkgs, ... }:

[
  "gui"
  "devel"
]
++ pkgs.lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
  "media/audio" # TODO: get this working on darwin
  "wm"
]
