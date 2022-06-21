{ kitty, stdenv }:

if stdenv.hostPlatform.isDarwin
then kitty.overrideAttrs (_: { doInstallCheck = false; })
else kitty
