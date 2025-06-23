cmarkit — CommonMark parser and renderer for OCaml
==================================================
%%VERSION%%

Cmarkit parses the [CommonMark specification]. It provides:

- A CommonMark parser for UTF-8 encoded documents. Link label resolution
  can be customized and a non-strict parsing mode can be activated to add: 
  strikethrough, LaTeX math, footnotes, task items and tables.
  
- An extensible abstract syntax tree for CommonMark documents with
  source location tracking and best-effort source layout preservation.

- Abstract syntax tree mapper and folder abstractions for quick and
  concise tree transformations.
  
- Extensible renderers for HTML, LaTeX and CommonMark with source
  layout preservation.

Cmarkit is distributed under the ISC license. It has no dependencies.

[CommonMark specification]: https://spec.commonmark.org/

Homepage: <https://erratique.ch/software/cmarkit>

## Installation

cmarkit can be installed with `opam`:

    opam install cmarkit
    opam install cmarkit cmdliner # For the cmarkit tool

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

The documentation can be consulted [online] or via `odig doc cmarkit`.

Questions are welcome but better asked on the [OCaml forum] than on
the issue tracker. 

[online]: https://erratique.ch/software/cmarkit/doc
[OCaml forum]: https://discuss.ocaml.org/

## Sample programs 

The [`cmarkit`] tool parses and renders CommonMark files in various
ways.

See also [`bench.ml`] and the [doc examples].

[`cmarkit`]: test/cmarkit_tool.ml
[`bench.ml`]: test/bench.ml
[doc examples]:  test/examples.ml

## Acknowledgements

A grant from the [OCaml Software Foundation] helped to bring the first
public release of `cmarkit`.

The `cmarkit` implementation benefited from the work of John
MacFarlane ([spec][CommonMark specification], [`cmark`]) and Martin
Mitáš ([`md4c`]).

[`cmark`]: https://github.com/commonmark/cmark
[`md4c`]: https://github.com/mity/md4c
[OCaml Software Foundation]: http://ocaml-sf.org/
