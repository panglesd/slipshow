# Contributing

## Releasing

In order to release a new version, you need to:

- Have an up to date engine, both in the `dist` (?) folder and in the ocaml data files:

```
$ make bundle
```

- Have an up to date compiler written in javascript, in release mode:

```
$ dune build
$ dune build --profile=release
$ rm bin/slipshow
$ echo "#\!/usr/bin/env node" > bin/slipshow
$ cat _build/default/compiler/src/bin/main_js.bc.js >> bin/slipshow
$ chmod a+x bin/slipshow
```

- Do the npm release

```
$ npm version patch         # Or minor or major, let's dream!
$ npm publish               # Publishing
```

- Do the github release

```
$ git push
$ # and push tags!
```

- Do the opam release

TBD!
