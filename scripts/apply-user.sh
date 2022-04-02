#!/bin/sh
nix build .#homeManagerConfigurations."$1".activationPackage
result/activate
