
- Data updated for Unicode 15.1.0 (no changes except 
  for the value of `Cmarkit.Doc.unicode_version`).

- Fix table extension column parsing, toplevel text inlines were being
  dropped. Thanks to Javier Chávarri for the report (#10).

- `List_item.make`, change default value of `after_marker` from 0 to 1.
  We don't want to generate invalid CommonMark by default. Thanks to 
  Rafał Gwoździński for the report (#9).

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
