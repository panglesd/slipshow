(** A plugin which updates an HTML element with the content of the code mirror
    editor *)

val slipshow_plugin :
  ?slipshow_js:Slipshow.Asset.t ->
  ?frontmatter:Slipshow.Frontmatter.resolved Slipshow.Frontmatter.t ->
  ?read_file:Slipshow.file_reader ->
  Brr.El.t ->
  Code_mirror.Extension.t
