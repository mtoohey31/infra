{ buildGoModule, gotop, stdenv }:

if stdenv.hostPlatform.isDarwin then
  gotop.override
  {
    buildGoModule = args: buildGoModule (args // {
      meta = args.meta // { broken = false; };
      patches = [ ./0001-fix-bump-gopsutil-to-fix-darwin-compatability.patch ];
      vendorSha256 = "G/hFpiOMgJfUiJfplpgtkcJKZMqM7WodrEl5wE0jgbY=";
    });
  }
else gotop
