FROM ocaml/opam:alpine-ocaml-4.14
RUN sudo apk add libev-dev openssl-dev libffi-dev gmp-dev
RUN sudo apk add openssl-libs-static
WORKDIR slipshow/

COPY --chown=opam *.opam .
RUN opam install -y --deps-only --with-test --with-doc .

COPY --chown=opam . .

