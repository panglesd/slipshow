brr — Browser programming toolkit for OCaml
===========================================

Brr is a toolkit for programming browsers in OCaml with the
[`js_of_ocaml`][jsoo] compiler. It provides:

* Interfaces to a selection of browser APIs.
* An OCaml console developer tool for live interaction 
  with programs running in web pages.
* A JavaScript FFI for idiomatic OCaml programming.

Brr is distributed under the ISC license. It depends on the
`js_of_ocaml` compiler and runtime – but not on its libraries or
syntax extension.

[jsoo]: https://ocsigen.org/js_of_ocaml

Homepage: <https://erratique.ch/software/brr>  

## Installation

Brr can be installed with `opam`:

    opam install brr

If you don't use `opam` consult the [`opam`](opam) file for build
instructions.

## Documentation

The documentation can be consulted [online] or via `odig doc brr`.

Questions are welcome but better asked on the [OCaml forum] than on 
the issue tracker.

[online]: https://erratique.ch/software/brr/doc
[OCaml forum]: https://discuss.ocaml.org/

## Sample programs

A few basic programs can be found in the [test suite](test).

You can run them with for example `b0 -- test_audio`, see 
`b0 list` for the list of tests.

