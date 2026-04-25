(** A plugin which updates an HTML element with the content of the code mirror
    editor *)

val slipshow_plugin :
  ?slipshow_js:Slipshow.Asset.t ->
  ?read_file:Slipshow.file_reader ->
  errors_el:Brr.El.t ->
  Brr.El.t ->
  Code_mirror.Extension.t
