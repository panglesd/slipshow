#!/bin/sh
# Runs the screenshot tests in Playwright's Docker image, so that the rendering
# does not depend on the fonts and libraries of the host. The HTML files must
# have been generated first, with `dune build`. The arguments are passed to
# `playwright test`.

set -e
cd "$(dirname "$0")"

dune build --profile release

# The image must have the same version of Playwright as the one installed by
# `npm ci`, otherwise it does not contain the right browsers.
VERSION=$(grep -A1 '"node_modules/@playwright/test"' package-lock.json |
              sed -n 's/.*"version": "\(.*\)".*/\1/p')
if [ -z "$VERSION" ]; then
    echo "Cannot find the version of @playwright/test in package-lock.json" >&2
    exit 1
fi

# The image runs as root by default: use the current user instead, so that the
# files written in the test folder (node_modules, screenshots, reports) are
# owned by them.
exec docker run --rm --init --ipc=host \
     --user "$(id -u):$(id -g)" -e HOME=/tmp -e CI \
     -v "$PWD:/tests" -w /tests \
     "mcr.microsoft.com/playwright:v$VERSION-noble" \
     sh -c 'npm ci --no-audit --no-fund && npx playwright test "$@"' sh "$@"
