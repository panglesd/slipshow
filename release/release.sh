#/usr/bin/env bash
set -xeuo pipefail

archive_name=$OUTPUT/slipshow-$TARGETOS-$TARGETARCH.tar

dune subst

dune build --profile release -p slipshow

# Executables are symlinks, follow with -h.
tar hcf "$archive_name" -C _build/install/default bin/slipshow
