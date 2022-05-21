#!/usr/bin/env -S nix shell --ignore-environment --keep GOPATH ../../#xcaddy nixpkgs#bash nixpkgs#coreutils nixpkgs#gnugrep --command bash

mv "$(XCADDY_SKIP_BUILD=1 xcaddy build --with github.com/caddy-dns/cloudflare@latest 2>&1 | tail -n 1 | grep -o '/tmp/.*$')/"* .
