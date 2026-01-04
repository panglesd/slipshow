type t
(** Editor panels *)

include Jv.CONV with type t := t

val create :
  ?mount:(unit -> unit) ->
  ?update:(Editor.View.Update.t -> unit) ->
  ?top:bool ->
  ?pos:int ->
  Brr.El.t ->
  t
