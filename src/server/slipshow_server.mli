val do_serve :
  port:int ->
  (unit ->
  ( (Slipshow.delayed * string (* warnings as string *)) * Fpath.Set.t,
    [ `Msg of string ] )
  result) ->
  (unit, [ `Msg of string ]) result

val do_watch :
  (unit -> (Fpath.Set.t, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result
