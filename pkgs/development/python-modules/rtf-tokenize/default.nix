{ python3Packages }:

python3Packages.buildPythonPackage rec {
  pname = "rtf_tokenize";
  version = "1.0.0";
  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "XD3zkNAEeb12N8gjv81v37Id3RuWroFUY95+HtOS1gg=";
  };
}
