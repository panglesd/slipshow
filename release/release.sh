#/usr/bin/env bash
set -xeuo pipefail

archive_name=$OUTPUT/slipshow-$TARGETOS-$TARGETARCH.tar

dune subst

# I've had sufficiently many issues with version to check. Hardcoding the file
# name is not satisfactory though.
if grep -q '%%VERSION%%' src/version/slipshow_version.ml; then
  echo "Error: the version watermarks were not substituted." >&2
  echo "(\`dune subst\` needs the git repository and its tags.)" >&2
  exit 1
fi

dune build --profile release -p slipshow

mkdir -p $OUTPUT

# Executables are symlinks, follow with -h.
tar hcf "$archive_name" -C _build/install/default bin/slipshow
