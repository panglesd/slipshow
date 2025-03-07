# Contributing

## Releasing

In order to release a new version, you need to:

### Check that the changelog is up to date

Do that! And write the tag in the changelog! And commit and push!

### Do the opam release

Use `dune-release`:
- Call `dune-release tag --dry-run` to check
- Call `dune-release tag` to do
- Push the tag
- Checkout the branch which has the tag
- Call `dune-release distrib`
- Call `dune-release publish distrib`
- Call `dune-release opam pkg`
- Call `dune-release opam submit`
- Verify that everything is right by comparing the `opam` file for the previous version, with this one!

- Rewrite the binary release announcement

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

