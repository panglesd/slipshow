
- `Cmarkit_latex`. Add option `?first_heading_level` to the renderer
  to set the LaTeX heading level to use for the first CommonMark
  heading level. A corresponding option `--first-heading-level` is
  added to `cmarkit latex`.  Thanks to Léo Andrès for the patch (#16).

- `Cmarkit.Mapper`, do not drop empty table cells. 
  Thanks to Hannes Mehnert for the report (#14).

- Fix crash (out of bounds exception) when lists are terminated by
  the end of file. Thanks to Ty Overby for the report (#18).

- Fix invalid markup generated for cancelled task items. 
  Thanks to Sebastien Mondet for the report (#15).

- Updated data for Unicode 16.0.0.

v0.3.0 2023-12-12 La Forclaz (VS)
---------------------------------

- Fix ordered item marker escaping. Thanks to Rafał Gwoździński for
  the report (#11).
  
- Data updated for Unicode 15.1.0 (no changes except 
  for the value of `Cmarkit.Doc.unicode_version`).

- Fix table extension column parsing, toplevel text inlines were being
  dropped. Thanks to Javier Chávarri for the report (#10).

- `List_item.make`, change default value of `after_marker` from 0 to 1.
  We don't want to generate invalid CommonMark by default. Thanks to 
  Rafał Gwoździński for the report (#9).

- Add option `-f/--full-featured`, to `cmarkit html`. A synonym for a
  bunch of existing options to generate a publishable document with extensions
  and math rendering without hassle.  See `cmarkit html --help` for details.
  
v0.2.0 2023-05-10 La Forclaz (VS)
---------------------------------

- Fix bug in `Block_lines.list_of_string`. Thanks to Rafał Gwoździński
  for the report and the fix (#7, #8).
- `Cmarkit.Mapper`. Fix non-sensical default map for `Image` nodes: do
  not delete `Image` nodes whose alt text maps to `None`, replace the
  alt text by `Inline.empty`. Thanks to Nicolás Ojeda Bär for the
  report and the fix (#6).

v0.1.0 2023-04-06 La Forclaz (VS)
---------------------------------

First release.

Supported by a grant from the OCaml Software Foundation.
