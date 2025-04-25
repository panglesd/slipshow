val do_serve :
  (unit -> (Slipshow.delayed * Fpath.Set.t, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result

val do_watch :
  (unit -> (Fpath.Set.t, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result
