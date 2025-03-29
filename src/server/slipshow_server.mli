val do_serve :
  [< `File of Fpath.t | `Stdin ] ->
  (unit -> (Slipshow.delayed, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result

val do_watch :
  [< `File of Fpath.t | `Stdin ] ->
  (unit -> (unit, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result
