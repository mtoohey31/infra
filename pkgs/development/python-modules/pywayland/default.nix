{ python3Packages }:

python3Packages.pywayland.overridePythonAttrs
  (oldAttrs: rec {
    version = "0.4.7";
    src = python3Packages.fetchPypi {
      inherit (oldAttrs) pname;
      inherit version;
      sha256 = "0IMNOPTmY22JCHccIVuZxDhVr41cDcKNkx8bp+5h2CU=";
    };
  })
