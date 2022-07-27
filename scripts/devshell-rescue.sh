#!/usr/bin/env bash

bindir="$(mktemp -d)"
echo "#!/bin/sh" > "$bindir/git-crypt-agessh"
chmod +x "$bindir/git-crypt-agessh"

PATH="$bindir:$PATH" bash -i <<'EOF'
eval "$(direnv hook bash)"
direnv reload
EOF

rm -rf "$bindir"
