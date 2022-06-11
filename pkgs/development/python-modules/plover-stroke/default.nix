{ python3Packages }:

python3Packages.buildPythonPackage rec {
  pname = "plover_stroke";
  version = "1.0.1";
  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "t+ZM0oDEwitFDC1L4due5IxCWEPzJbF3fi27HDyto8Q=";
  };
}
