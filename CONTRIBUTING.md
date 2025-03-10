# Contributing

## Releasing

In order to release a new version, you need to:

### Check that the changelog is up to date

Do that! And write the tag in the changelog! And commit and push!

### Do the binary release

First, fix https://github.com/panglesd/slipshow/issues/91
Then, update softprops/action-gh-release@v1 to create a draft release instead of directly a release.

- Write the binary release announcement (in the changelog)
- Call `dune-release tag --dry-run` to check
- Call `dune-release tag` to do the tag
- Push the tag
- Rewrite the binary release announcement if needed
- Check that readthedocs has picked up the new tag on stable

### Do the opam release

- Checkout the branch which has the tag
- Call `dune-release distrib`
- Call `dune-release publish distrib --draft` // A release already has been created. I don't know if this command allows a tag to have already been pushed/a release already been created.
  An alternative is to add using the GUI the asset (eg `_build/slipshow-0.1.0.tbz`).
  Use the `--dry-run` flag to be sure
- Call `dune-release opam pkg`
  It seems that there is some discrepencies between the release created by the CI (which has a leading `v`) and the one dune release expect to have been created (by itself).
  So, there might be a need to update the url.
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

