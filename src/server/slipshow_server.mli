val do_serve :
  port:int ->
  Fpath.t ->
  (unit ->
  ( (Slipshow.delayed * string (* warnings as string *)) * Fpath.Set.t,
    [ `Msg of string ] )
  result) ->
  unit

val do_watch :
  Fpath.t -> (unit -> (Fpath.Set.t, [ `Msg of string ]) result) -> unit
