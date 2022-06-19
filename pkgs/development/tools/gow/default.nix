{ buildGo118Module, gow-src }:

buildGo118Module rec {
  pname = "gow";
  version = src.shortRev;
  src = gow-src;
  vendorSha256 = "o6KltbjmAN2w9LMeS9oozB0qz9tSMYmdDW3CwUNChzA=";
}
