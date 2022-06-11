{ buildGo118Module, gow-src }:

buildGo118Module rec {
  pname = "gow";
  version = "0.1.0";
  src = gow-src;
  vendorSha256 = "o6KltbjmAN2w9LMeS9oozB0qz9tSMYmdDW3CwUNChzA=";
}
