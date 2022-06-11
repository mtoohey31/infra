{ isDarwin, pywal }:

if self.stdenv.hostPlatform.isDarwin then
  super.pywal.overrideAttrs
    (_: {
      prePatch = ''
        substituteInPlace pywal/util.py --replace pidof pgrep
      '';
    })
else super.pywal
