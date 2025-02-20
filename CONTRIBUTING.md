# Contributing

## Releasing

In order to release a new version, you need to:

### Check that the changelog is up to date

Do that!

### Have an up to date engine, both in the `dist` (?) folder and in the ocaml data files:

```
$ make bundle
```

This is likely to be updated to something less cumbersome

### Have an up to date compiler written in javascript, in release mode:

```
$ dune build
$ dune build --profile=release
$ rm bin/slipshow
$ echo "#\!/usr/bin/env node" > bin/slipshow
$ cat _build/default/compiler/src/bin/main_js.bc.js >> bin/slipshow
$ chmod a+x bin/slipshow
```

### Do the npm release

```
$ npm version patch         # Or minor or major, let's dream!
$ npm publish               # Publishing
```

### Do the github release

```
$ git push
$ # and push tags!
```

### Do the opam release

Use `dune-release`:
- Checkout the branch which has the tag
- Call `dune-release distrib`
- Call `dune-release publish distrib`
- Call `dune-release opam pkg`
- Call `dune-release opam submit`
- Verify that everything is right by comparing the `opam` file for the previous version, with this one!

### Make a slipshow-gui release

`dune install` the last release of slipshow.

Update the version on `gui/slipshow-gui/src-tauri/tauri.conf.json` (and maybe `gui/slipshow-gui/package.json`)

```
sliphub$ dune build
sliphub$ cd gui/slipshow-gui
sliphub$ npm run tauri dev # To test
```

Git commit and push. This will create a draft release. Finish it and undraft it.

### Make a slipshow-vscode release

Publish on vscode official repo

```
slipshow-vscode$ dune build
slipshow-vscode$ vsce package
slipshow-vscode$ vsce publish patch   # (or minor, major)
```

Publish on open-vsx: connect to open-vsx, login and manually publish the new vsix.

### Update sliphub

TODO

## Vendoring

Slipshow vendors a few modified dependencies. Currently it uses
[git-vendor](https://github.com/brettlangdon/git-vendor).
