# Contributing

If you are willing to contribute, thanks!

## Writing a theme

To write a theme, see [this page](https://slipshow.readthedocs.io/en/stable/themes.html). If you'd like it to be included in the set of builtin themes, the best is to open a PR with your theme added to the `src/themes/` directory. I can then help on the rest of the OCaml plumbing so you don't have to!

## Getting started

This project is written in OCaml, so you need to be able to compile such programs. The official website ocaml.org provides explanation on getting started with OCaml.

Once you have opam, and a switch ready, install the dependencies with:

```shell
opam install . --deps-only --with-dev-setup --with-test
```

Then, build with

```shell
dune build
```

You can run the version you just built with

```shell
dune exec slipshow -- <other options>
```

## Directory structure

The directory structure is the following:
- `docs/` for the readthedocs documentation
  - `docs/odoc/` for the doc build by `odoc` and served on ocaml.org
- `example/` for ... examples (to be kept up to date?! Is that going to make the repo big? TODO: add a dune rule for that)
- `release/` for scripts used in the release process
- `test/` for tests
- `vendor/` for vendored library, see the vendoring section of this document
- `src/` for the source:
  - `src/engine/` contains the code for the engine, the part translated to
    javascript that is run during a presentation, and that is responsible for
    reacting to the user's input etc.
    - `src/engine/themes/` contains the CSS themes.
  - `src/cli/` contains the code for the CLI parsing (using cmdliner) and calling
    the right entry point (preview server, compiler, ...)
  - `src/static_data/` contains static data such as highlightjs code to embed in a
    presentation.
  - `src/server/` contains the code for the preview server
    - `src/server/client/` contains the code for the client-side javascript of the preview server
  - `src/communication/` contains the types and utilities to serialize and
    deserialize data exchanged between server and client.
  - `src/previewer/` contains the code for the previewer panel (used by
    slipshow's preview mode but also sliphub, the VSCode extension, ...)

## Releasing

In order to release a new version, you need to:

### Update the name of the release

See `version_title` in `src/cli/main.ml`.

### Check that the changelog is up to date

Do that! And write the tag in the changelog! And commit and push!

### Do the binary release

- Write the binary release announcement (in the changelog)
- Call `dune-release tag --dry-run` to check
- Call `dune-release tag` to do the tag
- Push the tag
- Rewrite the binary release announcement if needed

### Do the opam release

- Checkout the branch which has the tag
- Call `dune-release distrib`
- Call `dune-release publish distrib --draft` // A release already has been created. I don't know if this command allows a tag to have already been pushed/a release already been created.
  An alternative is to add using the GUI the asset (eg `_build/slipshow-0.1.0.tbz`).
  Use the `--dry-run` flag to be sure
- Call `dune-release opam pkg` TODO: add --src-uri in the release guide to avoid having to modify it by hand (or forgetting to do so)
  It seems that there is some discrepencies between the release created by the CI (which has a leading `v`) and the one dune release expect to have been created (by itself).
  So, there might be a need to update the url.
- Call `dune-release opam submit`
- Verify that everything is right by comparing the `opam` file for the previous version, with this one!

### Do a ReadTheDocs release

- Make readthedocs pick up the new tag on stable, by commiting eg the new "Unreleased" section of the changelog

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
slipshow-vscode$ dune build --profile release
slipshow-vscode$ vsce package
slipshow-vscode$ vsce publish patch   # (or minor, major) OR NOTHING!
# if cannot publish due to expired token, do:
$ vsce publish -p <token>
```


Publish on open-vsx: connect to open-vsx, login and manually publish the new vsix (click on "PUBLISH" next to the avatar, top right. Send the vsix directly).

### Update sliphub

Use dune pkg!

## Vendoring

Slipshow vendors a few modified dependencies. Currently it uses
[git-vendor](https://github.com/brettlangdon/git-vendor).

- To add a new dependency, use `git vendor add <name> <repo> <ref>`. For instance:
  ```
  git vendor add brr git@github.com:panglesd/brr.git slipshow-vendor
  ```
- To update a dependency, use `git vendor update <name> <ref>`. For instance:

  ```
  git vendor update cmarkit markdown-attributes
  ```
- To upstream local changes to a dependency, use `git vendor upstream <name> <ref>`. For instance:
  ```
  git vendor upstream cmarkit markdown-attributes
  ```
