#/usr/bin/env bash
set -xeuo pipefail

archive_name=$OUTPUT/slipshow-$TARGETOS-$TARGETARCH.tar

dune subst

dune build --profile release -p slipshow

version=$(./_build/install/default/bin/slipshow --version)
echo "$version"

# I've had sufficiently many issues with version to check.
case "$version" in
  *%%*)
    echo "Error: the version watermarks were not substituted: $version" >&2
    echo "(\`dune subst\` needs the git repository and its tags.)" >&2
    exit 1
    ;;
esac

mkdir -p $OUTPUT

# Executables are symlinks, follow with -h.
tar hcf "$archive_name" -C _build/install/default bin/slipshow
