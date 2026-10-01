#!/bin/sh
set -eu
cd "$(dirname "$0")"
for f in *.sh .profile profile nextlevel prevlevel validate; do sh -n "$f"; done
exec python3 tests/integration.py "$@"
