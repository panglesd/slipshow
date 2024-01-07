val do_serve :
  [< `File of Fpath.t | `Stdin ] ->
  (unit -> (string, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result

val do_watch :
  [< `File of Fpath.t | `Stdin ] ->
  (unit -> (string, [ `Msg of string ]) result) ->
  (unit, [ `Msg of string ]) result
