FROM ocaml/opam:alpine-ocaml-4.14 AS deps
RUN sudo apk add libev-dev openssl-dev libffi-dev gmp-dev
RUN sudo apk add openssl-libs-static
WORKDIR slipshow/

COPY --chown=opam *.opam .
RUN opam install -y --deps-only --with-test --with-doc .

FROM deps AS build

ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ENV VERSION=$VERSION \
    TARGETOS=$TARGETOS \
    TARGETARCH=$TARGETARCH\
    OUTPUT=/tmp/release

COPY --chown=opam . .

RUN opam exec -- dune subst

ENV SLIPSHOW_STATIC=1

# Run the release script inside the build
RUN opam exec -- bash release/release.sh

# Export ONLY the compiled binaries to the host
FROM scratch
COPY --from=build /tmp/release /
