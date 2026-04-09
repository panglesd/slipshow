FROM ocaml/opam:alpine-ocaml-4.14
RUN sudo apk add libev-dev openssl-dev libffi-dev gmp-dev
RUN sudo apk add openssl-libs-static
WORKDIR slipshow/

COPY --chown=opam *.opam .
RUN opam install -y --deps-only --with-test --with-doc .

COPY --chown=opam . .

RUN opam exec -- dune subst

RUN sed -i 's/"()"/"(-cclib -static -cclib -no-pie)"/g' src/cli/static-linking-flags/static_linking_flags.ml

ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ENV VERSION=$VERSION TARGETOS=$TARGETOS TARGETARCH=$TARGETARCH OUTPUT=/tmp/release

# Run the release script inside the build
RUN opam exec -- bash release/release.sh

# Export ONLY the compiled binaries to the host
FROM scratch
COPY --from=0 /tmp/release /