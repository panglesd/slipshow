# Contributing

If you are willing to contribute, thanks!

## Writing a theme

To write a theme, see [this page](https://slipshow.readthedocs.io/en/stable/themes.html). If you'd like it to be included in the set of builtin themes, the best is to open a PR with your theme added to the `src/themes/` directory. I can then help on the rest of the OCaml plumbing so you don't have to!

## Improving the docs

Improvements to the docs are always welcome!

The source for the docs can be found in the `doc/`, as `.rst` files. In order to
be turned into the static html website, you need to have
[sphinx](https://www.sphinx-doc.org/en/master/). Moreover, if you add editable
slipshow examples, you also need to be able to [build the
project](#building-the-project).

Once you satisfy the requirement above, the docs are built with

```
$ make html
```

from the `docs/` directory.

## Building the project

This project is written in OCaml, so you need to be able to compile such programs. The official website [ocaml.org](https://ocaml.org) provides explanation on getting started with OCaml.

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
- `example/` stores the examples that are kept up to date with the slipshow
  version, by ensuring they are built at the same time as the docs.
- `release/` for scripts used in the release process
- `test/` for tests
- `vendor/` for vendored library, see the vendoring section of this document
- `src/` for the source:
  - `src/engine/` for all code running in the browser
  - `src/engine/runtime/` contains the code for the engine, the part translated to
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
  - `src/engine/previewer/` contains the code for the previewer panel (used by
    slipshow's preview mode but also sliphub, the VSCode extension, ...)
  - `src/lspishow/` contains the code for the lsp server.

## Getting more help

Absolutely do not hesitate to ask for help, either on the
[Zulip](https://slipshow.zulipchat.com/) or in [github
issues](https://github.com/panglesd/slipshow/issues). Whenever in doubt for the
implementation of a feature, it is better to start the discussion.

## AI use

Slipshow is a project for humans. I hope we have fun using it to present, assist presentations, and developping it. Fun is the main goal!

I enjoy writing code by hand, but I do not enjoy reviewing big PRs, so I probably won't if it has been written by an LLM. If it has been written by a human, I'll respect the work and time and will happily review the code!

If you have a doubt, open a PR or an issue, I don't bite!

AI use should also be disclaimed, and avoided in communication. Thanks!

## Releasing

In order to release a new version, you need to:

### Check that everything works fine

This includes:

- The docs:
  -
    ```
    $ cd docs/
    $ make clean
    $ make html
    $ firefox _build/html/index.html
    ```
  - Check the the pages look good
  - Check that all "kept up to date" examples look good
  - Update the "Slipshow version" for examples kept up to date (Currently the first four)
- Check that serve mode works
- Check that other dependants (sliphub, slipshow-vscode, ...) compile and work
  well

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
- Add using the GUI the asset (eg `_build/slipshow-0.1.0.tbz`) to the release.
<!-- Call `dune-release publish distrib --draft` // A release already has been created. I don't know if this command allows a tag to have already been pushed/a release already been created. -->
<!--   An alternative is to add using the GUI the asset (eg `_build/slipshow-0.1.0.tbz`). -->
<!--   Use the `--dry-run` flag to be sure -->
- Call `$ dune-release opam pkg --dist-uri https://github.com/panglesd/slipshow/releases/download/v0.X.0/slipshow-0.X.0.tbz`
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
