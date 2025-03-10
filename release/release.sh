#/usr/bin/env bash
set -xeuo pipefail

archive_name=$OUTPUT/slipshow-$TARGETOS-$TARGETARCH.tar

dune subst

sed -i 's/"()"/"(-cclib -static -cclib -no-pie)"/g' src/compiler/bin/static-linking-flags/static_linking_flags.ml

dune build --profile release -p slipshow

# Executables are symlinks, follow with -h.
tar hcf "$archive_name" -C _build/install/default bin/slipshow
