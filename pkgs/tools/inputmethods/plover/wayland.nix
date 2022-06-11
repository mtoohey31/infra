{ fetchFromGitHub, pkg-config, plover, python3Packages, wayland }:

plover.dev.overridePythonAttrs
  (oldAttrs: {
    src = fetchFromGitHub {
      owner = "openstenoproject";
      repo = "plover";
      rev = "fd5668a3ad9bd091289dd2e5e8e2c1dec063d51f";
      sha256 = "2xvcNcJ07q4BIloGHgmxivqGq1BuXwZY2XWPLbFrdXg=";
    };
    propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
      python3Packages.plover-stroke
      python3Packages.pywayland_0_4_7
      python3Packages.rtf-tokenize
    ];
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkg-config ];
    doCheck = false; # TODO: get tests working
    postPatch = ''
      sed -i /PyQt5/d setup.cfg
      substituteInPlace plover_build_utils/setup.py \
        --replace "/usr/share/wayland/wayland.xml" "${wayland}/share/wayland/wayland.xml"
    '';
  })
