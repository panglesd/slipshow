#!/usr/bin/env bash
set -xeuo pipefail

archive_name=$OUTPUT/slipshow-$TARGETOS-$TARGETARCH.tar
binary=./_build/install/default/bin/slipshow

dune subst

dune build --profile release -p slipshow

version=$("$binary" --version)
echo "$version"

# I've had sufficiently many issues with version to check.
case "$version" in
  *%%*)
    echo "Error: the version watermarks were not substituted: $version" >&2
    echo "(\`dune subst\` needs the git repository and its tags.)" >&2
    exit 1
    ;;
esac

# On macOS, check we are not shipping a binary that depends on the build
# machine's Homebrew installation: only Apple's own libraries may be linked
# dynamically. See src/cli/static-linking-flags/static_linking_flags.ml.
if [ "$(uname -s)" = "Darwin" ]; then
  otool -L "$binary"
  if otool -L "$binary" | tail -n +2 \
      | grep -qvE '^[[:space:]]*(/usr/lib/|/System/Library/)'; then
    echo "Error: the binary links against non-system libraries." >&2
    echo "It would not run on a machine without the same Homebrew setup." >&2
    exit 1
  fi
fi

mkdir -p $OUTPUT

# Executables are symlinks, follow with -h.
tar hcf "$archive_name" -C _build/install/default bin/slipshow
