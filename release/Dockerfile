FROM ocaml/opam:alpine-ocaml-4.14
RUN sudo apk add libev-dev openssl-dev libffi-dev gmp-dev
RUN sudo apk add openssl-libs-static
WORKDIR slipshow/

COPY --chown=opam *.opam .

ENV PTHREAD_STACK_MIN 2097152

RUN opam install -y --deps-only --with-test --with-doc .

COPY --chown=opam . .

RUN sed  -i 's/"()"/"(-cclib -static -cclib -no-pie)"/g' compiler/src/bin/static-linking-flags/static_linking_flags.ml

