{ kitty, stdenv }:

if stdenv.hostPlatform.isDarwin
then
  kitty.overrideAttrs
    (oldAttrs: {
      doInstallCheck = false;
      patches = (oldAttrs.patches or [ ]) ++ [
        ./0001-Revert-Use-actual-color-value-comparison-when-detect.patch
      ];
    })
else
  kitty.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0001-Revert-Use-actual-color-value-comparison-when-detect.patch
    ];
  })
