{ gnugrep, procps, pywal, stdenv, writeShellScript }:

if stdenv.hostPlatform.isDarwin then
  pywal.overrideAttrs
    (_: {
      prePatch = ''
        substituteInPlace pywal/util.py --replace pidof ${writeShellScript "pgrep" ''
          exec ${gnugrep}/bin/grep "''${@: -1}" <(${procps}/bin/ps -eo cmd)
        ''}
      '';
    })
else pywal
