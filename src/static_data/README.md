# Static data included in the slipshow compiler

Static data are 3-rd party tools that are embedded in the slipshow compiler. For instance the Mathjax math renderer, or highlightJS for syntax highlighting.

Here is how to add some static data in the Slipshow compiler:
- First, check that the licence is compatible with Slipshow's licence.
- Use either `ocaml-crunch` or `ppx_blob` to embed the content as OCaml module
- Embed in as fit in the compiled html
- Use the "has math/pdf/..." compiler pass to only embed the content if needed
- Remember to add the licence of the distributed project where needed: as a
  file, and on the main licence file, in the opam licence field.
- Document how you added the content, and how to update it, in this file. Do it,
  as you are going to forget about it in 5 minutes!

------------

## Highlight js

Here is how to include highlightJS:

- Download two archives from https://highlightjs.org/download
  - One containing none languages
    - Extract that archive and keep only `highlight.min.js`
  - One containing all languages,
    - Extract that archive and keep:
      - The licence
      - The languages/*.min.js
      - The styles/*.min.css (embed the images files from `styles/` as base64
        urls where they are used)
- To remove all .js but none .min.js you can use: `find . -type f -name "*.js" ! -name "*.min.js" -delete`
- Copy those files in src/static_data/highlightjs
