[PDF.js](https://github.com/mozilla/pdf.js/) is a javascript library for
rendering PDFs in a canvas. This repo contains OCaml bindings to its javascript
API.

I think that the best way to understand how to use it is to have a look at the
[example](https://github.com/panglesd/pdfjs_ocaml/tree/main/example), which is
the OCaml version of the PDF.js base64 pdf
[example](https://mozilla.github.io/pdf.js/examples/).

To test the example just run `dune build` and open `example/base64.html`.
