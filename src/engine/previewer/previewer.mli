type previewer

(** A previewer is meant for "live previewing without flickering".

    To create a previewer, you {e need} to provide an HTML element that contains
    exactly:
    - Nothing

    When you have a previewer, you can preview a source. For the moment, it has
    to be a {e source}: you cannot pass it a compiled file. *)

val create_previewer :
  ?initial_stage:int -> ?callback:(int -> unit) -> Brr.El.t -> previewer

val preview :
  ?slipshow_js:Slipshow.Asset.t ->
  ?frontmatter:Slipshow.Frontmatter.resolved Slipshow.Frontmatter.t ->
  ?read_file:Slipshow.file_reader ->
  previewer ->
  string ->
  unit

val preview_compiled : previewer -> Slipshow.delayed -> unit
val ids : previewer -> string * string
