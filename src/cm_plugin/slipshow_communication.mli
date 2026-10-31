(** A plugin which updates an HTML element with the content of the code mirror
    editor *)

val view_plugin :
  ?slipshow_js:Slipshow.Uri.t ->
  ?options:Slipshow.Frontmatter.Global.t ->
  errors_el:Brr.El.t ->
  Brr.El.t ->
  Code_mirror.View.ViewPlugin.t

val extension :
  ?slipshow_js:Slipshow.Uri.t ->
  ?options:Slipshow.Frontmatter.Global.t ->
  errors_el:Brr.El.t ->
  Brr.El.t ->
  Code_mirror.Extension.t
